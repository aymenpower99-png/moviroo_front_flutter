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
    // ── Warm start guard ──
    // If we already have cached live data (warm start), REST must NOT override
    // ETA, progress, arrivalTime, or distanceLeft. Those fields come from the
    // last WebSocket message and are more accurate than REST stale estimates.
    // REST is only used here for static metadata (driver name, vehicle, addresses,
    // phone, photo) that rarely change mid-ride.
    final isWarmStart = isRideDataReady;

    // ── Static fields (driver/vehicle/addresses) ──
    final newDriverName = dataLoader.backendDriverName.isNotEmpty
        ? dataLoader.backendDriverName
        : (widget.driverName ?? (isWarmStart ? rideState.driverName : ''));
    final newVehicleName = dataLoader.backendVehicleName.isNotEmpty
        ? dataLoader.backendVehicleName
        : (widget.vehicleName ?? (isWarmStart ? rideState.vehicleName : ''));
    final newVehicleMake = dataLoader.backendVehicleMake.isNotEmpty
        ? dataLoader.backendVehicleMake
        : (isWarmStart ? rideState.vehicleMake : '');
    final newVehicleModel = dataLoader.backendVehicleModel.isNotEmpty
        ? dataLoader.backendVehicleModel
        : (isWarmStart ? rideState.vehicleModel : '');
    final newVehicleColor = dataLoader.backendVehicleColor.isNotEmpty
        ? dataLoader.backendVehicleColor
        : (widget.vehicleColor ?? (isWarmStart ? rideState.vehicleColor : ''));
    final newPlateNumber = dataLoader.backendPlateNumber.isNotEmpty
        ? dataLoader.backendPlateNumber
        : (widget.plateNumber ?? (isWarmStart ? rideState.plateNumber : ''));
    final newPickupAddress = dataLoader.backendPickupAddress.isNotEmpty
        ? dataLoader.backendPickupAddress
        : (widget.pickupAddress ??
              (isWarmStart ? rideState.pickupAddress : ''));
    final newDropoffAddress = dataLoader.backendDropoffAddress.isNotEmpty
        ? dataLoader.backendDropoffAddress
        : (widget.dropoffAddress ??
              (isWarmStart ? rideState.dropoffAddress : ''));

    final newDriverPhoneNumber = dataLoader.backendDriverPhoneNumber.isNotEmpty
        ? dataLoader.backendDriverPhoneNumber
        : (isWarmStart ? rideState.driverPhoneNumber : '');

    // Driver rating from REST (0.0 means backend didn't provide one).
    final newDriverRating = dataLoader.backendDriverRating > 0
        ? dataLoader.backendDriverRating
        : (isWarmStart ? rideState.driverRating : 0.0);

    if (isWarmStart) {
      // Warm start: mutate only static metadata, preserve live WebSocket values.
      rideState = rideState.copyWith(
        driverName: newDriverName,
        vehicleName: newVehicleName,
        vehicleMake: newVehicleMake,
        vehicleModel: newVehicleModel,
        vehicleColor: newVehicleColor,
        plateNumber: newPlateNumber,
        pickupAddress: newPickupAddress,
        dropoffAddress: newDropoffAddress,
        driverPhotoUrl: dataLoader.backendDriverPhotoUrl.isNotEmpty
            ? dataLoader.backendDriverPhotoUrl
            : rideState.driverPhotoUrl,
        driverPhoneNumber: newDriverPhoneNumber,
        driverRating: newDriverRating,
      );
      return;
    }

    // ── Cold start ──
    // No cached live data yet. Build a fresh RideState with empty live fields.
    // The UI will stay in skeleton mode until the first WebSocket update arrives.
    rideState = RideState(
      phase: RidePhase.driverOnTheWay,
      progress: 0.0,
      etaMins: 0,
      arrivalTime: '',
      distanceLeft: '',
      driverName: newDriverName,
      vehicleName: newVehicleName,
      vehicleMake: newVehicleMake,
      vehicleModel: newVehicleModel,
      vehicleColor: newVehicleColor,
      plateNumber: newPlateNumber,
      pickupAddress: newPickupAddress,
      dropoffAddress: newDropoffAddress,
      driverPhotoUrl: dataLoader.backendDriverPhotoUrl,
      driverPhoneNumber: newDriverPhoneNumber,
      driverRating: newDriverRating,
    );
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
