part of track_ride_page;
// ── Callback methods mixin ───────────────────────────────────────────────────
// Contains all event handlers: driver location, animation, phase transitions,
// and camera events.
// ─────────────────────────────────────────────────────────────────────────────

mixin _TrackRideCallbacksMixin on State<TrackRidePage>, _TrackRideStateMixin {
  // ── Driver location update (from WebSocket) ───────────────────────────────
  void onDriverLocationUpdate(
    double lat,
    double lng,
    Map<String, dynamic> locationData,
  ) {
    debugPrint('📍 WebSocket location update: lat=$lat, lng=$lng');
    final newPos = mbx.Point(coordinates: mbx.Position(lng, lat));

    // Calculate bearing only if displacement is meaningful (>= 3m).
    // Tiny GPS deltas amplify into noisy/random bearings → keep previous bearing.
    double bearing = driverBearing;
    if (driverPos != null) {
      final distance = mapController.distanceMeters(driverPos!, newPos);
      if (distance >= 3.0) {
        bearing = mapController.calcBearing(driverPos!, newPos);
        debugPrint(
          '🧭 Calculated bearing: $bearing° (distance=${distance.toStringAsFixed(1)}m)',
        );
      } else {
        debugPrint(
          '🧭 Skip bearing update — displacement too small (${distance.toStringAsFixed(2)}m)',
        );
      }
    }

    // Extract speed from WebSocket data (driver sends speed_kmh)
    final speedKmh = (locationData['speed_kmh'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
      '🎬 Calling setTargetPosition (speed=${speedKmh.toStringAsFixed(1)} km/h)',
    );
    driverAnimController.setTargetPosition(newPos, bearing, speedKmh: speedKmh);

    // Update progress from WebSocket data
    if (locationData.isNotEmpty && mounted) {
      setState(() {
        rideState = progressCalculator.updateProgressFromWebSocket(
          rideState,
          locationData,
        );
        isRideDataReady = true;
      });
      _writeCache();
    }
  }

  // ── Driver animation position callback (every animation tick) ─────────────
  void onDriverPositionUpdate(mbx.Point pos, double bearing) {
    if (!mounted) return;

    final isFirstFix = !hasFirstDriverFix;

    setState(() {
      driverPos = pos;
      driverBearing = bearing;
      if (isFirstFix) {
        hasFirstDriverFix = true;
        isInitializing = false;
        isDriverLocationReady = true;
      }
    });
    mapController.updateDriverMarker(pos, bearing);

    // First location fix: center camera on driver so user sees them immediately.
    if (isFirstFix) {
      debugPrint('🎯 FIRST DRIVER FIX — centering camera');
      mapController.controller?.flyTo(
        mbx.CameraOptions(
          center: pos,
          zoom: 15.0,
          bearing: bearing,
          pitch: 0.0,
        ),
        mbx.MapAnimationOptions(duration: 500),
      );
      return;
    }
  }

  // ── Camera follow callback (called every animation tick) ──────────────────
  void onCameraFollow(mbx.Point pos) {
    if (cameraFollowMode && rideState.phase == RidePhase.rideInProgress) {
      mapController.controller?.flyTo(
        mbx.CameraOptions(
          center: pos,
          zoom: 16.0,
          bearing: driverBearing,
          pitch: 45.0,
        ),
        mbx.MapAnimationOptions(duration: 300),
      );
    }
  }

  // ── Phase transition callbacks (from WebSocket events) ────────────────────
  void onDriverEnroute(int? etaMins) {
    if (etaMins != null && mounted) {
      setState(() {
        rideState = rideState.copyWith(
          etaMins: etaMins,
          arrivalTime: phaseManager.calcArrivalTime(etaMins),
        );
      });
      _writeCache();
    }
  }

  void onDriverArrived() {
    if (rideState.phase != RidePhase.driverArrived && mounted) {
      HapticFeedback.mediumImpact();
      pulseAnim.repeat(reverse: true);
      setState(() {
        rideState = rideState.copyWith(phase: RidePhase.driverArrived);
      });
    }
  }

  void onRideStarted() {
    if (rideState.phase != RidePhase.rideInProgress &&
        rideState.phase != RidePhase.rideEnded &&
        mounted) {
      setState(() {
        rideState = rideState.copyWith(phase: RidePhase.rideInProgress);
      });
    }
  }

  void onRideCompleted(Map<String, dynamic> data) {
    if (rideState.phase != RidePhase.rideEnded && mounted) {
      HapticFeedback.lightImpact();
      setState(() {
        rideState = rideState.copyWith(
          phase: RidePhase.rideEnded,
          progress: 1.0,
        );
      });
      // Trip is over — clear the tracking cache so the next ride starts fresh.
      RideTrackingCache.instance.remove(widget.rideId);
    }
  }

  // ── Camera changed event ──────────────────────────────────────────────────
  void onCameraChanged(mbx.CameraChangedEventData event) {
    mapController.updateZoom(event.cameraState.zoom);
  }

  // ── Map created callback ──────────────────────────────────────────────────
  void onMapCreated(mbx.MapboxMap controller) {
    mapController.setMapController(controller);
  }

  // ── Style loaded callback ─────────────────────────────────────────────────
  Future<void> onStyleLoaded() async {
    debugPrint('🗺️ _onStyleLoaded called');
    await mapController.initializeAnnotationManagers();
    debugPrint('🗺️ Annotation managers initialized');
    await mapController.initializeMarkers(pickupLatLng, dropoffLatLng);
    debugPrint('🗺️ Pickup/dropoff markers initialized');
    mapController.fitBoundsToRoute(pickupLatLng, dropoffLatLng);
    debugPrint('🗺️ Camera fit to route');

    // Disable Mapbox built-in controls
    mapController.controller?.scaleBar.updateSettings(
      mbx.ScaleBarSettings(enabled: false),
    );
    mapController.controller?.compass.updateSettings(
      mbx.CompassSettings(enabled: false),
    );
    mapController.controller?.logo.updateSettings(
      mbx.LogoSettings(enabled: false),
    );
    // Disable tilt gesture to enforce flat 2D map
    mapController.controller?.gestures.updateSettings(
      mbx.GesturesSettings(pitchEnabled: false),
    );

    /* ── Create driver car layer from cached position ────────────────────
       On warm start driverPos is restored from cache.  We create the 3D
       model layer NOW (while the style is ready) so the car is visible
       instantly, before WebSocket connects.  updateDriverMarker() later
       only mutates the GeoJSON source — fast and lightweight. ── */
    if (driverPos != null) {
      debugPrint(
        '🗺️ Style ready — creating driver model layer from cached position',
      );
      await mapController.setupDriverModel(driverPos!);
    }

    debugPrint('🗺️ Mapbox controls disabled, pitch gesture disabled');
  }
}
