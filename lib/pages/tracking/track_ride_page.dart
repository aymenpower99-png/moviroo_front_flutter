import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../theme/app_colors.dart';
import 'widgets/_bottom_panel.dart';
import '_trip_completed_overlay.dart';
import 'ride_state.dart';
import '../../services/passenger_tracking_socket.dart';
import '../../services/ride_api_service.dart';
import '../../services/osrm_route_service.dart';

// ── OSM tile styles (free, no API key) ───────────────────────────────────────
const _osmStyleLight = 'https://tiles.openfreemap.org/styles/liberty';
const _osmStyleDark  = 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

/// Passenger-side live tracking page.
///
/// Pass ride data as route arguments:
/// ```dart
/// Navigator.pushNamed(context, AppRouter.trackRide, arguments: {
///   'rideId':          'uuid',
///   'pickupLat':       36.8,
///   'pickupLon':       10.1,
///   'dropoffLat':      36.9,
///   'dropoffLon':      10.2,
///   'pickupAddress':   '123 Rue ...',
///   'dropoffAddress':  '456 Ave ...',
///   'driverName':      'Ali Ben Salem',
///   'vehicleName':     'Toyota Corolla',
///   'vehicleColor':    'White',
///   'plateNumber':     '123 TUN 456',
///   'etaMins':         7,
/// });
/// ```
class TrackRidePage extends StatefulWidget {
  final String rideId;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final String pickupAddress;
  final String dropoffAddress;
  final String driverName;
  final String vehicleName;
  final String vehicleColor;
  final String plateNumber;
  final int?   etaMins;

  const TrackRidePage({
    super.key,
    this.rideId         = '',
    this.pickupLat      = 36.8189,
    this.pickupLon      = 10.1658,
    this.dropoffLat     = 36.8300,
    this.dropoffLon     = 10.1750,
    this.pickupAddress  = 'Pickup',
    this.dropoffAddress = 'Drop-off',
    this.driverName     = 'Driver',
    this.vehicleName    = 'Vehicle',
    this.vehicleColor   = '',
    this.plateNumber    = '',
    this.etaMins,
  });

  @override
  State<TrackRidePage> createState() => _TrackRidePageState();
}

class _TrackRidePageState extends State<TrackRidePage>
    with TickerProviderStateMixin {
  // ── Ride phase state ───────────────────────────────────────────────────────
  late RideState _rideState;

  // ── Map ────────────────────────────────────────────────────────────────────
  MapLibreMapController? _mapController;
  bool _routeDrawn = false;

  // ── Driver position ────────────────────────────────────────────────────────
  LatLng? _driverPos;
  double  _driverBearing = 0;
  Circle? _driverCircle;

  // ── Smooth car animation ───────────────────────────────────────────────────
  late AnimationController _moveAnim;
  LatLng? _animStart;
  LatLng? _animEnd;

  // ── Pulse animation (arrival) ──────────────────────────────────────────────
  late AnimationController _pulseAnim;

  // ── ETA overlay ────────────────────────────────────────────────────────────
  String _etaText  = '';
  String _distText = '';
  DateTime? _lastEtaRefresh;

  // ── Services ───────────────────────────────────────────────────────────────
  PassengerTrackingSocket? _socket;
  Timer? _pollTimer;

  // ── Helpers ────────────────────────────────────────────────────────────────
  LatLng get _pickupLatLng  => LatLng(widget.pickupLat,  widget.pickupLon);
  LatLng get _dropoffLatLng => LatLng(widget.dropoffLat, widget.dropoffLon);

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    final eta = widget.etaMins ?? 7;
    _rideState = RideState(
      phase:          RidePhase.driverOnTheWay,
      progress:       0.0,
      etaMins:        eta,
      arrivalTime:    _calcArrivalTime(eta),
      distanceLeft:   '',
      driverName:     widget.driverName,
      vehicleName:    widget.vehicleName,
      vehicleColor:   widget.vehicleColor,
      plateNumber:    widget.plateNumber,
      pickupAddress:  widget.pickupAddress,
      dropoffAddress: widget.dropoffAddress,
    );

    if (eta > 0) _etaText = '$eta min';

    _moveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(_onMoveAnimTick);

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.rideId.isNotEmpty) {
      _connectSocket();
      _startPollingFallback();
    }
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────
  void _connectSocket() {
    _socket = PassengerTrackingSocket()
      ..onDriverEnroute     = (etaMins) {
        if (etaMins != null && mounted) {
          setState(() {
            _etaText  = '$etaMins min';
            _rideState = _rideState.copyWith(
              etaMins:     etaMins,
              arrivalTime: _calcArrivalTime(etaMins),
            );
          });
        }
      }
      ..onLocationUpdate    = _onDriverLocationUpdate
      ..onDriverArrived     = _advanceToArrived
      ..onRideStarted       = _advanceToRideStarted
      ..onRideCompleted     = (_) => _advanceToRideEnded();
    _socket!.connect(widget.rideId);
  }

  // ── Polling fallback ───────────────────────────────────────────────────────
  void _startPollingFallback() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  Future<void> _poll() async {
    final data = await RideApiService().getTripStatus(widget.rideId);
    if (data == null || !mounted) return;

    final driverLoc = data['driver_location'] as Map<String, dynamic>?;
    if (driverLoc != null) {
      final lat = (driverLoc['latitude']  as num?)?.toDouble();
      final lng = (driverLoc['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) _onDriverLocationUpdate(lat, lng);
    }

    final status = data['status'] as String?;
    switch (status) {
      case 'ARRIVED':
        if (_rideState.phase == RidePhase.driverOnTheWay) _advanceToArrived();
        break;
      case 'STARTED':
      case 'IN_TRIP':
        if (_rideState.phase != RidePhase.rideInProgress &&
            _rideState.phase != RidePhase.rideEnded) {
          _advanceToRideStarted();
        }
        break;
      case 'COMPLETED':
        if (_rideState.phase != RidePhase.rideEnded) _advanceToRideEnded();
        break;
    }
  }

  // ── Driver location update ─────────────────────────────────────────────────
  void _onDriverLocationUpdate(double lat, double lng) {
    final newPos = LatLng(lat, lng);

    if (_driverPos != null) {
      _driverBearing = _calcBearing(_driverPos!, newPos);
    }

    _animStart  = _driverPos ?? newPos;
    _animEnd    = newPos;
    _driverPos  = newPos;

    _moveAnim.forward(from: 0.0);
    _animateCamera(newPos, bearing: _driverBearing);
    _maybeRefreshEta(newPos);
  }

  // ── Smooth animation tick ──────────────────────────────────────────────────
  void _onMoveAnimTick() {
    if (_animStart == null || _animEnd == null || _mapController == null) return;
    final t   = Curves.easeInOut.transform(_moveAnim.value);
    final lat = _lerp(_animStart!.latitude,  _animEnd!.latitude,  t);
    final lng = _lerp(_animStart!.longitude, _animEnd!.longitude, t);
    _updateDriverMarker(LatLng(lat, lng));
  }

  // ── ETA refresh (throttled to 30s) ────────────────────────────────────────
  void _maybeRefreshEta(LatLng driverPos) {
    final now = DateTime.now();
    if (_lastEtaRefresh != null &&
        now.difference(_lastEtaRefresh!).inSeconds < 30) return;
    _lastEtaRefresh = now;
    _refreshEta(driverPos);
  }

  Future<void> _refreshEta(LatLng driverPos) async {
    final dest = _rideState.phase == RidePhase.rideInProgress
        ? _dropoffLatLng
        : _pickupLatLng;
    final result = await OsrmRouteService.fetchRoute(driverPos, dest);
    if (result == null || !mounted) return;
    final etaMins = (result.durationSeconds / 60).ceil();
    setState(() {
      _etaText  = result.etaText;
      _distText = result.distanceText;
      _rideState = _rideState.copyWith(
        etaMins:     etaMins,
        arrivalTime: _calcArrivalTime(etaMins),
        distanceLeft: result.distanceText,
      );
    });
  }

  // ── Phase transitions ──────────────────────────────────────────────────────
  void _advanceToArrived() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _rideState = _rideState.copyWith(
        phase:    RidePhase.driverArrived,
        progress: 1.0,
      );
    });
    _pulseAnim.repeat(reverse: true);
  }

  void _advanceToRideStarted() {
    if (!mounted) return;
    setState(() {
      _rideState = _rideState.copyWith(
        phase:    RidePhase.rideInProgress,
        progress: 0.0,
      );
    });
    _fitBoundsToRoute();
  }

  void _advanceToRideEnded() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _pollTimer?.cancel();
    setState(() {
      _rideState = _rideState.copyWith(
        phase:    RidePhase.rideEnded,
        progress: 1.0,
      );
    });
  }

  // ── Map callbacks ──────────────────────────────────────────────────────────
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    if (_mapController == null) return;

    // Pickup marker
    await _mapController!.addSymbol(SymbolOptions(
      geometry:   _pickupLatLng,
      iconImage:  'marker-15',
      iconSize:   1.8,
      iconColor:  '#22C55E',
      textField:  'Pickup',
      textOffset: const Offset(0, 2.0),
      textColor:  '#22C55E',
      textSize:   11,
    ));

    // Dropoff marker
    await _mapController!.addSymbol(SymbolOptions(
      geometry:   _dropoffLatLng,
      iconImage:  'marker-15',
      iconSize:   1.8,
      iconColor:  '#A855F7',
      textField:  'Drop-off',
      textOffset: const Offset(0, 2.0),
      textColor:  '#A855F7',
      textSize:   11,
    ));

    await _drawRoute();
    _fitBoundsToRoute();
  }

  // ── Route drawing ──────────────────────────────────────────────────────────
  Future<void> _drawRoute() async {
    if (_mapController == null || _routeDrawn) return;
    _routeDrawn = true;

    final result =
        await OsrmRouteService.fetchRoute(_pickupLatLng, _dropoffLatLng);

    if (result != null && result.points.length >= 2) {
      if (mounted) {
        final etaMins = (result.durationSeconds / 60).ceil();
        setState(() {
          _etaText  = result.etaText;
          _distText = result.distanceText;
          _rideState = _rideState.copyWith(
            etaMins:     etaMins,
            arrivalTime: _calcArrivalTime(etaMins),
            distanceLeft: result.distanceText,
          );
        });
      }

      // Glow layer
      await _mapController!.addLine(LineOptions(
        geometry:    result.points,
        lineColor:   '#A855F7',
        lineWidth:   7.0,
        lineOpacity: 0.15,
      ));
      // Main route
      await _mapController!.addLine(LineOptions(
        geometry:    result.points,
        lineColor:   '#A855F7',
        lineWidth:   4.0,
        lineOpacity: 0.85,
      ));
    } else {
      // Straight-line fallback
      await _mapController!.addLine(LineOptions(
        geometry:    [_pickupLatLng, _dropoffLatLng],
        lineColor:   '#A855F7',
        lineWidth:   4.0,
        lineOpacity: 0.8,
      ));
    }
  }

  // ── Driver marker ──────────────────────────────────────────────────────────
  Future<void> _updateDriverMarker(LatLng pos) async {
    if (_mapController == null) return;
    if (_driverCircle != null) {
      await _mapController!.removeCircle(_driverCircle!);
    }
    _driverCircle = await _mapController!.addCircle(CircleOptions(
      geometry:          pos,
      circleRadius:      10,
      circleColor:       '#A855F7',
      circleStrokeWidth: 3,
      circleStrokeColor: '#FFFFFF',
    ));
  }

  // ── Camera ─────────────────────────────────────────────────────────────────
  void _fitBoundsToRoute() {
    if (_mapController == null) return;
    final sw = LatLng(
      math.min(_pickupLatLng.latitude,  _dropoffLatLng.latitude),
      math.min(_pickupLatLng.longitude, _dropoffLatLng.longitude),
    );
    final ne = LatLng(
      math.max(_pickupLatLng.latitude,  _dropoffLatLng.latitude),
      math.max(_pickupLatLng.longitude, _dropoffLatLng.longitude),
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        left: 60, right: 60, top: 120, bottom: 300,
      ),
    );
  }

  void _animateCamera(LatLng target, {double bearing = 0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target:  target,
        zoom:    15.0,
        bearing: bearing,
        tilt:    30.0,
      )),
    );
  }

  // ── Math helpers ───────────────────────────────────────────────────────────
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _calcBearing(LatLng from, LatLng to) {
    final dLon = _rad(to.longitude - from.longitude);
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(to.latitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  double _rad(double deg) => deg * math.pi / 180;
  double _deg(double rad) => rad * 180 / math.pi;

  String _calcArrivalTime(int etaMins) {
    final arrival = DateTime.now().add(Duration(minutes: etaMins));
    return '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _socket?.disconnect();
    _pollTimer?.cancel();
    _moveAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final top    = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── MapLibre GL ──────────────────────────────────────────────
            Positioned.fill(
              child: MapLibreMap(
                styleString: isDark ? _osmStyleDark : _osmStyleLight,
                initialCameraPosition: CameraPosition(
                  target: _pickupLatLng,
                  zoom:   13.0,
                ),
                onMapCreated:            _onMapCreated,
                onStyleLoadedCallback:   _onStyleLoaded,
                compassEnabled:          false,
                rotateGesturesEnabled:   true,
                tiltGesturesEnabled:     true,
                trackCameraPosition:     true,
              ),
            ),

            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top:  top + 8,
              left: 12,
              child: _MapBtn(
                icon:  Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),

            // ── ETA / distance overlay ───────────────────────────────────
            if (_etaText.isNotEmpty || _distText.isNotEmpty)
              Positioned(
                top:   top + 8,
                right: 16,
                child: _EtaOverlay(
                  eta:      _etaText,
                  distance: _distText,
                  isDark:   isDark,
                ),
              ),

            // ── Fit-bounds button ────────────────────────────────────────
            Positioned(
              right:  16,
              bottom: 380,
              child: _MapBtn(
                icon:  Icons.fit_screen_rounded,
                onTap: _fitBoundsToRoute,
              ),
            ),

            // ── Center-on-driver button ──────────────────────────────────
            Positioned(
              right:  16,
              bottom: 324,
              child: _MapBtn(
                icon: Icons.my_location_rounded,
                onTap: () {
                  if (_driverPos != null) {
                    _animateCamera(_driverPos!, bearing: _driverBearing);
                  } else {
                    _fitBoundsToRoute();
                  }
                },
              ),
            ),

            // ── Bottom panel ─────────────────────────────────────────────
            BottomPanel(
              rideState:   _rideState,
              pickupLabel: widget.pickupAddress,
              dropLabel:   widget.dropoffAddress,
              onImHere:    () {}, // passenger acknowledges arrival
              onContinue:  () => Navigator.maybePop(context),
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
                      end:   Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: _rideState.phase == RidePhase.rideEnded
                  ? TripCompletedOverlay(
                      key:        const ValueKey('trip_completed'),
                      rideState:  _rideState,
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

// ── ETA Overlay ───────────────────────────────────────────────────────────────

class _EtaOverlay extends StatelessWidget {
  final String eta;
  final String distance;
  final bool   isDark;

  const _EtaOverlay({
    required this.eta,
    required this.distance,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eta.isNotEmpty)
            _OverlayRow(icon: Icons.access_time_rounded, text: eta),
          if (distance.isNotEmpty) ...[
            const SizedBox(height: 4),
            _OverlayRow(icon: Icons.route_rounded, text: distance),
          ],
        ],
      ),
    );
  }
}

class _OverlayRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _OverlayRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      AppColors.text(context),
            ),
          ),
        ],
      );
}

// ── Map floating button ───────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData   icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : Colors.white)
              .withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: AppColors.text(context)),
        ),
      ),
    );
  }
}



