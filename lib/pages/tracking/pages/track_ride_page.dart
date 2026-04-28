import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../theme/app_colors.dart';
import '../widgets/ui/bottom_panel.dart';
import '../widgets/map/map_btn.dart';
import '../widgets/map/driver_3d_car.dart';
import '../widgets/overlays/trip_completed_overlay.dart';
import '../models/ride_state.dart';
import '../controllers/tracking_map_controller.dart';
import '../utils/map_constants.dart';
import '../services/ride_data_loader.dart';
import '../services/driver_animation_controller.dart';
import '../services/ride_connection_service.dart';
import '../services/ride_phase_manager.dart';

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

  // ── Pulse animation (arrival) ──────────────────────────────────────────────
  late AnimationController _pulseAnim;

  // ── Services ───────────────────────────────────────────────────────────────
  late RideConnectionService _connectionService;
  final RidePhaseManager _phaseManager = RidePhaseManager();

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
    final eta = widget.etaMins ?? 7;
    _rideState = RideState(
      phase: RidePhase.driverOnTheWay,
      progress: 0.0,
      etaMins: eta,
      arrivalTime: _phaseManager.calcArrivalTime(eta),
      distanceLeft: '',
      driverName: _driverName,
      vehicleName: _vehicleName,
      vehicleColor: _vehicleColor,
      plateNumber: _plateNumber,
      pickupAddress: _pickupAddress,
      dropoffAddress: _dropoffAddress,
    );
  }

  // ── Driver location update ─────────────────────────────────────────────────
  void _onDriverLocationUpdate(double lat, double lng) {
    final newPos = mbx.Point(coordinates: mbx.Position(lng, lat));

    // Calculate bearing if we have a previous position
    double bearing = _driverBearing;
    if (_driverPos != null) {
      bearing = _mapController.calcBearing(_driverPos!, newPos);
    }

    // Use driver animation controller
    _driverAnimController.setTargetPosition(newPos, bearing);
  }

  // ── Driver animation callback ───────────────────────────────────────────────
  void _onDriverPositionUpdate(mbx.Point pos, double bearing) {
    if (!mounted) return;
    setState(() {
      _driverPos = pos;
      _driverBearing = bearing;
    });
    _mapController.updateDriverMarker(pos, bearing);

    // Camera follow mode
    if (_cameraFollowMode && _rideState.phase == RidePhase.rideInProgress) {
      _mapController.controller?.setCamera(
        mbx.CameraOptions(
          center: pos,
          zoom: 15.0,
          bearing: bearing,
          pitch: 30.0,
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
          pitch: 30.0,
        ),
      );
    }
  }

  // ── Phase transition callbacks ───────────────────────────────────────────────
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
      setState(() {
        _rideState = _phaseManager.advanceToArrived(_rideState, _pulseAnim);
      });
    }
  }

  void _onRideStarted() {
    if (_rideState.phase != RidePhase.rideInProgress &&
        _rideState.phase != RidePhase.rideEnded &&
        mounted) {
      setState(() {
        _rideState = _phaseManager.advanceToRideStarted(_rideState);
      });
    }
  }

  void _onRideCompleted(Map<String, dynamic> data) {
    if (_rideState.phase != RidePhase.rideEnded && mounted) {
      setState(() {
        _rideState = _phaseManager.advanceToRideEnded(_rideState);
      });
    }
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
      onLocationUpdate: _onDriverLocationUpdate,
      onDriverArrived: _onDriverArrived,
      onRideStarted: _onRideStarted,
      onRideCompleted: _onRideCompleted,
    );

    // Load ride details from backend
    _loadRideDetails().then((_) {
      if (mounted) {
        _initializeRideState();

        _pulseAnim = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        );

        if (widget.rideId.isNotEmpty) {
          _connectionService.connect();
          _connectionService.startPolling(_rideState, (newState) {
            if (mounted) {
              setState(() {
                _rideState = newState;
              });
            }
          });
        }
      }
    });
  }

  // ── Map callbacks ──────────────────────────────────────────────────────────
  void _onMapCreated(mbx.MapboxMap controller) {
    _mapController.setMapController(controller);
  }

  Future<void> _onStyleLoaded() async {
    await _mapController.initializeAnnotationManagers();
    await _mapController.initializeMarkers(_pickupLatLng, _dropoffLatLng);
    // Route line removed
    // await _mapController.drawRoute(_pickupLatLng, _dropoffLatLng);
    _mapController.fitBoundsToRoute(_pickupLatLng, _dropoffLatLng);

    // Disable scale bar, compass, and logo
    _mapController.controller?.scaleBar.updateSettings(
      mbx.ScaleBarSettings(enabled: false),
    );
    _mapController.controller?.compass.updateSettings(
      mbx.CompassSettings(enabled: false),
    );
    _mapController.controller?.logo.updateSettings(
      mbx.LogoSettings(enabled: false),
    );
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
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: (event) => _onStyleLoaded(),
              ),
            ),

            // ── 3D Driver Car Overlay ─────────────────────────────────────
            if (_mapController.isReady && _driverPos != null)
              Driver3DCar(
                mapController: _mapController.controller!,
                driverPosition: _driverPos!,
                bearing: _driverBearing,
                visible: _rideState.phase == RidePhase.rideInProgress,
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

            // ── Fit-bounds button ────────────────────────────────────────
            Positioned(
              right: 16,
              bottom: 380,
              child: MapBtn(
                icon: Icons.fit_screen_rounded,
                onTap: () => _mapController.fitBoundsToRoute(
                  _pickupLatLng,
                  _dropoffLatLng,
                ),
              ),
            ),

            // ── Center-on-driver button ──────────────────────────────────
            Positioned(
              right: 16,
              bottom: 324,
              child: MapBtn(
                icon: _cameraFollowMode
                    ? Icons.location_searching_rounded
                    : Icons.my_location_rounded,
                onTap: () {
                  setState(() {
                    _cameraFollowMode = !_cameraFollowMode;
                  });
                  if (_driverPos != null) {
                    _mapController.animateCamera(
                      _driverPos!,
                      bearing: _driverBearing,
                    );
                  } else {
                    _mapController.fitBoundsToRoute(
                      _pickupLatLng,
                      _dropoffLatLng,
                    );
                  }
                },
              ),
            ),

            // ── Bottom panel ─────────────────────────────────────────────
            BottomPanel(
              rideState: _rideState,
              pickupLabel: _pickupAddress,
              dropLabel: _dropoffAddress,
              onImHere: () {}, // passenger acknowledges arrival
              onContinue: () => Navigator.maybePop(context),
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
