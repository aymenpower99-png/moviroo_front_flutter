import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../theme/app_colors.dart';
import '../widgets/ui/bottom_panel.dart';
import '../widgets/map/map_btn.dart';
import '../widgets/overlays/trip_completed_overlay.dart';
import '../models/ride_state.dart';
import '../controllers/tracking_map_controller.dart';
import '../utils/map_constants.dart';
import '../services/ride_data_loader.dart';
import '../services/driver_animation_controller.dart';
import '../services/ride_connection_service.dart';
import '../services/ride_phase_manager.dart';
import '../services/progress_calculator.dart';

class TrackRidePage extends StatefulWidget {
  final String rideId;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? driverName;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;
  final int? etaMins;

  const TrackRidePage({
    super.key,
    required this.rideId,
    this.pickupLat,
    this.pickupLon,
    this.dropoffLat,
    this.dropoffLon,
    this.pickupAddress,
    this.dropoffAddress,
    this.driverName,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
    this.etaMins,
  });

  @override
  State<TrackRidePage> createState() => _TrackRidePageState();
}

class _TrackRidePageState extends State<TrackRidePage>
    with TickerProviderStateMixin {
  // ── Ride phase state ───────────────────────────────────────────────────────
  RideState _rideState = RideState(
    phase: RidePhase.driverOnTheWay,
    progress: 0.0,
    etaMins: 7,
    arrivalTime: '',
    distanceLeft: '',
    driverName: '',
    vehicleName: '',
    vehicleColor: '',
    plateNumber: '',
    pickupAddress: '',
    dropoffAddress: '',
  );

  // ── Backend data loader ─────────────────────────────────────────────────────
  final RideDataLoader _dataLoader = RideDataLoader();

  // ── Map controller ─────────────────────────────────────────────────────────
  late TrackingMapController _mapController;

  // ── Driver position (for 3D car) ────────────────────────────────────────────
  mbx.Point? _driverPos;
  double _driverBearing = 0;

  // ── Driver animation controller ─────────────────────────────────────────────
  late DriverAnimationController _driverAnimController;

  // ── Camera follow mode ───────────────────────────────────────────────────
  bool _cameraFollowMode = false;

  // ── Loading / initialization state ───────────────────────────────────────
  bool _isInitializing = true;
  String _initStatus = 'Loading ride details...';
  bool _hasFirstDriverFix = false;

  // ── Pulse animation (arrival) ──────────────────────────────────────────────
  late AnimationController _pulseAnim;

  // ── Services ───────────────────────────────────────────────────────────────
  late RideConnectionService _connectionService;
  final RidePhaseManager _phaseManager = RidePhaseManager();
  final ProgressCalculator _progressCalculator = ProgressCalculator();

  // ── Helpers ────────────────────────────────────────────────────────────────
  mbx.Point get _pickupLatLng => mbx.Point(
    coordinates: mbx.Position(
      widget.pickupLon ?? _dataLoader.backendPickupLon,
      widget.pickupLat ?? _dataLoader.backendPickupLat,
    ),
  );
  mbx.Point get _dropoffLatLng => mbx.Point(
    coordinates: mbx.Position(
      widget.dropoffLon ?? _dataLoader.backendDropoffLon,
      widget.dropoffLat ?? _dataLoader.backendDropoffLat,
    ),
  );

  String get _pickupAddress =>
      widget.pickupAddress ?? _dataLoader.backendPickupAddress;
  String get _dropoffAddress =>
      widget.dropoffAddress ?? _dataLoader.backendDropoffAddress;
  String get _driverName => widget.driverName ?? _dataLoader.backendDriverName;
  String get _vehicleName =>
      widget.vehicleName ?? _dataLoader.backendVehicleName;
  String get _vehicleColor =>
      widget.vehicleColor ?? _dataLoader.backendVehicleColor;
  String get _plateNumber =>
      widget.plateNumber ?? _dataLoader.backendPlateNumber;

  // ── Load ride details from backend ───────────────────────────────────────────
  Future<void> _loadRideDetails() async {
    await _dataLoader.loadRideDetails(widget.rideId);
    if (mounted) {
      setState(() {});
    }
  }

  // ── Initialize ride state after backend data is loaded ─────────────────────
  void _initializeRideState() {
    // Use REST ETA if available, otherwise fallback to widget ETA or default
    final eta = _dataLoader.backendEtaMins ?? widget.etaMins ?? 7;
    // Use REST progress if available, otherwise default to 0
    final progress = _dataLoader.backendProgress ?? 0.0;
    // Calculate distance left from REST data if available
    String distanceLeft = '';
    if (_dataLoader.backendRemainingDistanceMeters != null) {
      final meters = _dataLoader.backendRemainingDistanceMeters!;
      if (meters >= 1000) {
        distanceLeft = '${(meters / 1000).toStringAsFixed(1)} km';
      } else {
        distanceLeft = '${meters.toInt()} m';
      }
    }

    _rideState = RideState(
      phase: RidePhase.driverOnTheWay,
      progress: progress,
      etaMins: eta,
      arrivalTime: _phaseManager.calcArrivalTime(eta),
      distanceLeft: distanceLeft,
      driverName: _driverName,
      vehicleName: _vehicleName,
      vehicleColor: _vehicleColor,
      plateNumber: _plateNumber,
      pickupAddress: _pickupAddress,
      dropoffAddress: _dropoffAddress,
    );
  }

  // ── Driver location update ─────────────────────────────────────────────────
  void _onDriverLocationUpdate(
    double lat,
    double lng,
    Map<String, dynamic> locationData,
  ) {
    debugPrint('📍 WebSocket location update: lat=$lat, lng=$lng');
    final newPos = mbx.Point(coordinates: mbx.Position(lng, lat));

    // Calculate bearing only if displacement is meaningful (>= 3m).
    // Tiny GPS deltas amplify into noisy/random bearings → keep previous bearing.
    double bearing = _driverBearing;
    if (_driverPos != null) {
      final distance = _mapController.distanceMeters(_driverPos!, newPos);
      if (distance >= 3.0) {
        bearing = _mapController.calcBearing(_driverPos!, newPos);
        debugPrint(
          '🧭 Calculated bearing: $bearing° (distance=${distance.toStringAsFixed(1)}m)',
        );
      } else {
        debugPrint(
          '🧭 Skip bearing update — displacement too small (${distance.toStringAsFixed(2)}m)',
        );
      }
    }

    // Use driver animation controller
    debugPrint('🎬 Calling setTargetPosition');
    _driverAnimController.setTargetPosition(newPos, bearing);

    // Update progress from WebSocket data
    if (locationData.isNotEmpty && mounted) {
      setState(() {
        _rideState = _progressCalculator.updateProgressFromWebSocket(
          _rideState,
          locationData,
        );
      });
    }
  }

  // ── Driver animation callback ───────────────────────────────────────────────
  void _onDriverPositionUpdate(mbx.Point pos, double bearing) {
    if (!mounted) return;

    final isFirstFix = !_hasFirstDriverFix;

    setState(() {
      _driverPos = pos;
      _driverBearing = bearing;
      if (isFirstFix) {
        _hasFirstDriverFix = true;
        _isInitializing = false;
      }
    });
    _mapController.updateDriverMarker(pos, bearing);

    // First location fix: center camera on driver so user sees them immediately.
    if (isFirstFix) {
      debugPrint('🎯 FIRST DRIVER FIX — centering camera');
      _mapController.controller?.setCamera(
        mbx.CameraOptions(
          center: pos,
          zoom: 15.0,
          bearing: bearing,
          pitch: 0.0,
        ),
      );
      return;
    }

    // Subsequent updates: only follow if camera follow mode is active.
    if (_cameraFollowMode && _rideState.phase == RidePhase.rideInProgress) {
      _mapController.controller?.setCamera(
        mbx.CameraOptions(
          center: pos,
          zoom: 15.0,
          bearing: bearing,
          pitch: 0.0,
        ),
      );
    }
  }

  // ── Camera follow callback ───────────────────────────────────────────────────
  void _onCameraFollow(mbx.Point pos) {
    if (_cameraFollowMode && _rideState.phase == RidePhase.rideInProgress) {
      _mapController.controller?.setCamera(
        mbx.CameraOptions(
          center: pos,
          zoom: 15.0,
          bearing: _driverBearing,
          pitch: 0.0,
        ),
      );
    }
  }

  // ── Phase transition callbacks (from WebSocket events) ────────────────
  void _onDriverEnroute(int? etaMins) {
    if (etaMins != null && mounted) {
      setState(() {
        _rideState = _rideState.copyWith(
          etaMins: etaMins,
          arrivalTime: _phaseManager.calcArrivalTime(etaMins),
        );
      });
    }
  }

  void _onDriverArrived() {
    if (_rideState.phase != RidePhase.driverArrived && mounted) {
      HapticFeedback.mediumImpact();
      _pulseAnim.repeat(reverse: true);
      setState(() {
        _rideState = _rideState.copyWith(phase: RidePhase.driverArrived);
      });
    }
  }

  void _onRideStarted() {
    if (_rideState.phase != RidePhase.rideInProgress &&
        _rideState.phase != RidePhase.rideEnded &&
        mounted) {
      setState(() {
        _rideState = _rideState.copyWith(phase: RidePhase.rideInProgress);
      });
    }
  }

  void _onRideCompleted(Map<String, dynamic> data) {
    if (_rideState.phase != RidePhase.rideEnded && mounted) {
      HapticFeedback.lightImpact();
      setState(() {
        _rideState = _rideState.copyWith(
          phase: RidePhase.rideEnded,
          progress: 1.0,
        );
      });
    }
  }

  void _onCameraChanged(mbx.CameraChangedEventData event) {
    _mapController.updateZoom(event.cameraState.zoom);
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Initialize map controller
    _mapController = TrackingMapController(
      onDriverMarkerUpdated: (pos, bearing) {
        if (mounted) {
          setState(() {
            _driverPos = pos;
            _driverBearing = bearing;
          });
        }
      },
    );

    // Initialize driver animation controller
    _driverAnimController = DriverAnimationController(
      vsync: this,
      onPositionUpdate: _onDriverPositionUpdate,
      onCameraFollow: _onCameraFollow,
    );

    // Initialize connection service
    _connectionService = RideConnectionService(
      rideId: widget.rideId,
      onDriverEnroute: _onDriverEnroute,
      onLocationUpdate: (lat, lng, data) =>
          _onDriverLocationUpdate(lat, lng, data),
      onDriverArrived: _onDriverArrived,
      onRideStarted: _onRideStarted,
      onRideCompleted: _onRideCompleted,
    );

    // Pulse anim is needed before any state checks below
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Parallel initialization: fire HTTP + WebSocket simultaneously
    // so we don't wait for the HTTP round-trip before opening the socket.
    _initializeInParallel();
  }

  Future<void> _initializeInParallel() async {
    // Open WebSocket immediately (independent of ride details).
    if (widget.rideId.isNotEmpty) {
      _connectionService.connect();
      if (mounted) {
        setState(() => _initStatus = 'Connecting to driver...');
      }
    }

    // In parallel: fetch ride details from backend.
    try {
      await _loadRideDetails();
    } catch (e) {
      debugPrint('❌ _loadRideDetails failed: $e');
    }

    if (!mounted) return;
    _initializeRideState();

    // Use REST driver location for immediate first render if available.
    // We delegate to DriverAnimationController.setTargetPosition() which has
    // a "first update" branch that calls onPositionUpdate -> _onDriverPositionUpdate,
    // and that callback handles setState, marker update and camera centering.
    if (_dataLoader.backendDriverLat != null &&
        _dataLoader.backendDriverLon != null) {
      final initialPos = mbx.Point(
        coordinates: mbx.Position(
          _dataLoader.backendDriverLon!,
          _dataLoader.backendDriverLat!,
        ),
      );

      debugPrint(
        '🎯 REST INITIAL RENDER — driver location + progress + ETA from RoutingService',
      );
      // Single source of truth: animation controller's first-render path.
      _driverAnimController.setTargetPosition(initialPos, 0.0);
    }

    // If no driver location from REST, wait for WebSocket
    setState(() {
      if (!_hasFirstDriverFix) {
        _initStatus = 'Waiting for driver location...';
      }
    });
  }

  // ── Map callbacks ──────────────────────────────────────────────────────────
  void _onMapCreated(mbx.MapboxMap controller) {
    _mapController.setMapController(controller);
  }

  Future<void> _onStyleLoaded() async {
    debugPrint('🗺️ _onStyleLoaded called');
    await _mapController.initializeAnnotationManagers();
    debugPrint('🗺️ Annotation managers initialized');
    await _mapController.initializeMarkers(_pickupLatLng, _dropoffLatLng);
    debugPrint('🗺️ Pickup/dropoff markers initialized');
    // Route line removed
    // await _mapController.drawRoute(_pickupLatLng, _dropoffLatLng);
    _mapController.fitBoundsToRoute(_pickupLatLng, _dropoffLatLng);
    debugPrint('🗺️ Camera fit to route');

    // Disable Mapbox built-in controls
    _mapController.controller?.scaleBar.updateSettings(
      mbx.ScaleBarSettings(enabled: false),
    );
    _mapController.controller?.compass.updateSettings(
      mbx.CompassSettings(enabled: false),
    );
    _mapController.controller?.logo.updateSettings(
      mbx.LogoSettings(enabled: false),
    );
    // Disable tilt gesture to enforce flat 2D map
    _mapController.controller?.gestures.updateSettings(
      mbx.GesturesSettings(pitchEnabled: false),
    );
    debugPrint('🗺️ Mapbox controls disabled, pitch gesture disabled');
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pulseAnim.dispose();
    _driverAnimController.dispose();
    _connectionService.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Mapbox Map ──────────────────────────────────────────────
            Positioned.fill(
              child: mbx.MapWidget(
                styleUri: MapConstants.mapboxStyleUrl,
                cameraOptions: mbx.CameraOptions(
                  center: _pickupLatLng,
                  zoom: 13.0,
                  pitch: 0.0,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: (event) => _onStyleLoaded(),
                onCameraChangeListener: _onCameraChanged,
              ),
            ),

            // ── Loading overlay (shown until first driver fix) ──────────
            if (_isInitializing)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _initStatus,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: MapBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),

            // ── Right-side map buttons ────────────────────────────────────
            Positioned(
              right: 16,
              top: (MediaQuery.of(context).size.height - 300) / 2,
              child: Column(
                children: [
                  // Driver location button
                  MapBtn(
                    icon: Icons.directions_car,
                    onTap: () {
                      if (_driverPos != null) {
                        _mapController.animateCamera(
                          _driverPos!,
                          bearing: _driverBearing,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Route overview button
                  MapBtn(
                    icon: Icons.map,
                    onTap: () {
                      _mapController.fitBoundsToPickupAndDropoff(
                        _pickupLatLng,
                        _dropoffLatLng,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Bottom panel ─────────────────────────────────────────────
            BottomPanel(
              rideState: _rideState,
              pickupLabel: _pickupAddress,
              dropLabel: _dropoffAddress,
              onContinue: () => Navigator.maybePop(context),
              onChatTap: () {
                Navigator.pushNamed(
                  context,
                  'chat',
                  arguments: {
                    'rideId': widget.rideId,
                    'driverName': _rideState.driverName,
                  },
                );
              },
            ),

            // ── Trip-completed overlay ───────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: _rideState.phase == RidePhase.rideEnded
                  ? TripCompletedOverlay(
                      key: const ValueKey('trip_completed'),
                      rideState: _rideState,
                      onContinue: () => Navigator.maybePop(context),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}
