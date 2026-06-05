part of track_ride_page;

// ── State fields mixin ────────────────────────────────────────────────────────
// Contains all state variables, helper getters, and initialization helpers.
// Used as a mixin on _TrackRidePageState.
// ─────────────────────────────────────────────────────────────────────────────

mixin _TrackRideStateMixin on State<TrackRidePage> {
  // ── Ride phase state ─────────────────────────────────────────────────────
  /// Seeded in [initRide] with navigation args so the first frame shows real
  /// data instead of hard-coded placeholders that cause UI jumping.
  late RideState rideState;

  // ── Backend data loader ──────────────────────────────────────────────────
  final RideDataLoader dataLoader = RideDataLoader();

  // ── Map controller ───────────────────────────────────────────────────────
  late TrackingMapController mapController;

  // ── Driver position (for 3D car) ─────────────────────────────────────────
  mbx.Point? driverPos;
  double driverBearing = 0;

  // ── Driver animation controller ──────────────────────────────────────────
  late DriverAnimationController driverAnimController;

  // ── Camera follow mode ───────────────────────────────────────────────────
  bool cameraFollowMode = false;

  // ── Loading / initialization state ──────────────────────────────────────
  bool isInitializing = true;
  String initStatus = 'Loading ride details...';
  bool hasFirstDriverFix = false;

  /// True when the REST response has been processed and [rideState] holds
  /// validated backend data.  Gates the [BottomPanel] so the user never sees
  /// a broken intermediate state.
  bool isRideDataReady = false;

  /// True when we have a valid driver GPS fix (from REST or WebSocket).
  /// Gates the 3D car marker.
  bool isDriverLocationReady = false;

  /// True when we've received at least one live WebSocket update with ETA/progress.
  /// Used to distinguish cached data from live data and prevent showing stale values.
  bool hasLiveWebSocketData = false;

  // ── Pulse animation (arrival) ────────────────────────────────────────────
  late AnimationController pulseAnim;

  // ── Services ─────────────────────────────────────────────────────────────
  late RideConnectionService connectionService;
  final RidePhaseManager phaseManager = RidePhaseManager();
  final ProgressCalculator progressCalculator = ProgressCalculator();

  // ── Helpers ───────────────────────────────────────────────────────────────
  mbx.Point get pickupLatLng => mbx.Point(
    coordinates: mbx.Position(
      widget.pickupLon ?? dataLoader.backendPickupLon,
      widget.pickupLat ?? dataLoader.backendPickupLat,
    ),
  );

  mbx.Point get dropoffLatLng => mbx.Point(
    coordinates: mbx.Position(
      widget.dropoffLon ?? dataLoader.backendDropoffLon,
      widget.dropoffLat ?? dataLoader.backendDropoffLat,
    ),
  );

  String get pickupAddress =>
      widget.pickupAddress ?? dataLoader.backendPickupAddress;
  String get dropoffAddress =>
      widget.dropoffAddress ?? dataLoader.backendDropoffAddress;
  String get driverName => widget.driverName ?? dataLoader.backendDriverName;
  String get vehicleName => widget.vehicleName ?? dataLoader.backendVehicleName;
  String get vehicleColor =>
      widget.vehicleColor ?? dataLoader.backendVehicleColor;
  String get plateNumber => widget.plateNumber ?? dataLoader.backendPlateNumber;

  // ── Load ride details from backend ──────────────────────────────────────
  Future<void> loadRideDetails() async {
    await dataLoader.loadRideDetails(widget.rideId);
    if (mounted) setState(() {});
  }

  // ── Initialize ride state after backend data is loaded ──────────────────
  ///
  /// Cold start (`!isRideDataReady`): builds a fresh [RideState] from REST
  /// data, falling back to widget args for static fields.
  ///
  /// Warm start (`isRideDataReady`): only overrides fields where the backend
  /// returned non-null values.  Preserves cached ETA / progress when the REST
  /// response is empty or fails, preventing a "good → broken" regression.
  void initializeRideState() {
    // ── Freshness gating for REST driver location ──
    final last = dataLoader.backendDriverLastUpdatedAt;
    final hasFreshDriverLoc =
        dataLoader.backendDriverLat != null &&
        dataLoader.backendDriverLon != null &&
        last != null &&
        DateTime.now().difference(last).inSeconds <= 60;

    // ── ETA ──
    final int? backendEta = dataLoader.backendEtaMins;
    final int newEta = (hasFreshDriverLoc && backendEta != null)
        ? (backendEta > 180 ? 0 : backendEta)
        : (isRideDataReady ? rideState.etaMins : 0);

    // ── Progress ──
    final double newProgress =
        (hasFreshDriverLoc && dataLoader.backendProgress != null)
        ? dataLoader.backendProgress!.clamp(0.0, 1.0)
        : (isRideDataReady ? rideState.progress : 0.0);

    // ── Distance left ──
    String newDistanceLeft = isRideDataReady ? rideState.distanceLeft : '';
    if (hasFreshDriverLoc &&
        dataLoader.backendRemainingDistanceMeters != null) {
      final meters = dataLoader.backendRemainingDistanceMeters!;
      newDistanceLeft = meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km'
          : '${meters.toInt()} m';
    }

    // ── Arrival time ──
    final String newArrivalTime = newEta > 0
        ? phaseManager.calcArrivalTime(newEta)
        : rideState.arrivalTime;

    // ── Static fields (driver/vehicle/addresses) ──
    // These change rarely; prefer backend when available, else widget args,
    // else keep cached values on warm start.
    final newDriverName = dataLoader.backendDriverName.isNotEmpty
        ? dataLoader.backendDriverName
        : (widget.driverName ?? (isRideDataReady ? rideState.driverName : ''));
    final newVehicleName = dataLoader.backendVehicleName.isNotEmpty
        ? dataLoader.backendVehicleName
        : (widget.vehicleName ??
              (isRideDataReady ? rideState.vehicleName : ''));
    final newVehicleColor = dataLoader.backendVehicleColor.isNotEmpty
        ? dataLoader.backendVehicleColor
        : (widget.vehicleColor ??
              (isRideDataReady ? rideState.vehicleColor : ''));
    final newPlateNumber = dataLoader.backendPlateNumber.isNotEmpty
        ? dataLoader.backendPlateNumber
        : (widget.plateNumber ??
              (isRideDataReady ? rideState.plateNumber : ''));
    final newPickupAddress = dataLoader.backendPickupAddress.isNotEmpty
        ? dataLoader.backendPickupAddress
        : (widget.pickupAddress ??
              (isRideDataReady ? rideState.pickupAddress : ''));
    final newDropoffAddress = dataLoader.backendDropoffAddress.isNotEmpty
        ? dataLoader.backendDropoffAddress
        : (widget.dropoffAddress ??
              (isRideDataReady ? rideState.dropoffAddress : ''));

    final newDriverPhoneNumber = dataLoader.backendDriverPhoneNumber.isNotEmpty
        ? dataLoader.backendDriverPhoneNumber
        : (isRideDataReady ? rideState.driverPhoneNumber : '');

    rideState = RideState(
      phase: RidePhase.driverOnTheWay,
      progress: newProgress,
      etaMins: newEta,
      arrivalTime: newArrivalTime,
      distanceLeft: newDistanceLeft,
      driverName: newDriverName,
      vehicleName: newVehicleName,
      vehicleColor: newVehicleColor,
      plateNumber: newPlateNumber,
      pickupAddress: newPickupAddress,
      dropoffAddress: newDropoffAddress,
      driverPhotoUrl: dataLoader.backendDriverPhotoUrl,
      driverPhoneNumber: newDriverPhoneNumber,
    );

    // ── Readiness: only flip true when we have live WebSocket data ─────────────
    // Don't show panel based on REST data - wait for WebSocket to prevent fake data flash
    if (hasLiveWebSocketData) {
      isRideDataReady = true;
      _writeCache();
    }
  }

  // ── Persist current snapshot to cache ────────────────────────────────────
  void _writeCache() {
    // Only persist snapshots that carry meaningful UI data to avoid
    // poisoning warm starts with empty values.
    final valid =
        (rideState.etaMins > 0) ||
        (rideState.driverName.isNotEmpty) ||
        (rideState.pickupAddress.isNotEmpty &&
            rideState.dropoffAddress.isNotEmpty);
    if (!valid) return;

    RideTrackingCache.instance.set(
      widget.rideId,
      rideState,
      driverPos?.coordinates.lat.toDouble(),
      driverPos?.coordinates.lng.toDouble(),
      driverBearing,
    );
  }
}
