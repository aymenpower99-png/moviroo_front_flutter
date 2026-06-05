part of track_ride_page;
// ── Lifecycle mixin ───────────────────────────────────────────────────────────
// Contains initState, dispose, and the parallel initialization flow
// (HTTP + WebSocket fired simultaneously).
// ─────────────────────────────────────────────────────────────────────────────

mixin _TrackRideLifecycleMixin
    on State<TrackRidePage>, _TrackRideStateMixin, _TrackRideCallbacksMixin {
  void initRide() {
    // ── 1. Try warm start from cache ───────────────────────────────────────
    final cached = RideTrackingCache.instance.get(widget.rideId);
    if (cached != null) {
      debugPrint(
        '♻️ WARM START — restoring cached ride state for ${widget.rideId}',
      );
      rideState = cached.rideState;
      // Cached WebSocket data is immediately ready — show the panel right away.
      isRideDataReady = true;
      isInitializing = false;

      if (cached.driverLat != null && cached.driverLon != null) {
        driverPos = mbx.Point(
          coordinates: mbx.Position(cached.driverLon!, cached.driverLat!),
        );
        driverBearing = cached.driverBearing ?? 0.0;
        isDriverLocationReady = true;
        hasFirstDriverFix = true;
      }
    } else {
      // Cold start: no valid data yet — BottomPanel will stay hidden.
      debugPrint('❄️ COLD START — no cache for ${widget.rideId}');
      rideState = RideState(
        phase: RidePhase.driverOnTheWay,
        progress: 0.0,
        etaMins: 0,
        arrivalTime: '',
        distanceLeft: '',
        driverName: widget.driverName ?? '',
        vehicleName: widget.vehicleName ?? '',
        vehicleColor: widget.vehicleColor ?? '',
        plateNumber: widget.plateNumber ?? '',
        pickupAddress: widget.pickupAddress ?? '',
        dropoffAddress: widget.dropoffAddress ?? '',
        driverPhoneNumber: '',
      );
    }

    // Initialize map controller
    mapController = TrackingMapController(
      onDriverMarkerUpdated: (pos, bearing) {
        if (mounted) {
          setState(() {
            driverPos = pos;
            driverBearing = bearing;
          });
        }
      },
    );

    // Initialize driver animation controller
    driverAnimController = DriverAnimationController(
      vsync: this as TickerProvider,
      onPositionUpdate: onDriverPositionUpdate,
      onCameraFollow: onCameraFollow,
    );

    // If we have a cached position, seed the animation controller so the car
    // appears immediately and can glide to the next GPS update.
    if (driverPos != null) {
      driverAnimController.setTargetPosition(driverPos!, driverBearing);
    }

    // Initialize connection service
    connectionService = RideConnectionService(
      rideId: widget.rideId,
      onDriverEnroute: onDriverEnroute,
      onLocationUpdate: (lat, lng, data) =>
          onDriverLocationUpdate(lat, lng, data),
      onDriverArrived: onDriverArrived,
      onRideStarted: onRideStarted,
      onRideCompleted: onRideCompleted,
    );

    // Pulse anim must be ready before any phase checks
    pulseAnim = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 1000),
    );

    // Fire HTTP + WebSocket in background (will refresh cached data)
    initializeInParallel();
  }

  Future<void> initializeInParallel() async {
    // Open WebSocket immediately (independent of ride details).
    if (widget.rideId.isNotEmpty) {
      connectionService.connect();
      if (mounted && !isRideDataReady) {
        setState(() => initStatus = 'Connecting to driver...');
      }
    }

    // In parallel: fetch ride details from backend.
    // REST is only used for static metadata (driver name, vehicle, addresses,
    // phone, photo). Live fields (ETA, progress, arrivalTime) come from WebSocket
    // or cache; REST stale values are ignored.
    try {
      await loadRideDetails();
    } catch (e) {
      debugPrint('❌ _loadRideDetails failed: $e');
    }

    if (!mounted) return;

    // Refresh static metadata silently. On warm start this mutates only
    // driver/vehicle/address fields and preserves cached live WebSocket values.
    initializeRideState();

    // Use REST driver location for an immediate GPS fix if available and fresh.
    final last = dataLoader.backendDriverLastUpdatedAt;
    final hasFreshDriverLoc =
        dataLoader.backendDriverLat != null &&
        dataLoader.backendDriverLon != null &&
        last != null &&
        DateTime.now().difference(last).inSeconds <= 60;

    if (hasFreshDriverLoc) {
      final initialPos = mbx.Point(
        coordinates: mbx.Position(
          dataLoader.backendDriverLon!,
          dataLoader.backendDriverLat!,
        ),
      );
      debugPrint(
        '🎯 REST driver location fix — seeding marker while WebSocket connects',
      );
      driverAnimController.setTargetPosition(initialPos, 0.0);
      if (mounted) {
        setState(() {
          driverPos = initialPos;
          driverBearing = 0.0;
          isDriverLocationReady = true;
          hasFirstDriverFix = true;
        });
      }
    }

    // Cold start: keep the loading pill until WebSocket delivers live data.
    if (mounted && !isRideDataReady) {
      setState(() {
        initStatus = 'Waiting for driver location...';
      });
    }
  }

  void disposeRide() {
    // Persist the latest snapshot so the next open is a warm start.
    _writeCache();
    pulseAnim.dispose();
    driverAnimController.dispose();
    connectionService.dispose();
  }
}
