import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_colors.dart';
import '../../../../services/mapbox/mapbox_service.dart' as svc;
import 'widgets.dart';
import 'utils.dart';

/// Map-based location picker used to confirm a single location (pickup or
/// drop-off). The map is full-screen, a fixed Flutter widget pin stays at the
/// centre of the screen and the map moves beneath it. While the map is being
/// dragged the pin is lifted up; when the map stops it bounces back down.
class MapLocationPicker extends StatefulWidget {
  /// Label shown inside the confirm button, e.g. "Confirm pickup".
  final String confirmLabel;

  /// Title shown at the top of the bottom sheet, e.g. "Set your pickup spot".
  final String title;

  /// Subtitle shown under the title.
  final String subtitle;

  /// Optional initial address that pre-fills the input field.
  final String? initialAddress;

  const MapLocationPicker({
    super.key,
    this.confirmLabel = 'Confirm pickup',
    this.title = 'Choose your pickup location',
    this.subtitle = 'Drag map to move pin',
    this.initialAddress,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker>
    with SingleTickerProviderStateMixin {
  // ── Map ──────────────────────────────────────────────────────────────────
  mbx.MapboxMap? _mapboxMap;

  // Default center: Tunis (same as driver app)
  static const double _defaultLat = 36.8065;
  static const double _defaultLon = 10.1815;

  // ── Pin animation ────────────────────────────────────────────────────────
  late final AnimationController _pinController;
  late final Animation<double> _pinAnim;
  bool _isDragging = false;

  // ── Address state ────────────────────────────────────────────────────────
  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingAddress = false;
  double _currentLat = _defaultLat;
  double _currentLon = _defaultLon;
  bool _isLoadingLocation = false;
  bool _isOutOfCoverage = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';

    // Controller drives the drop-and-bounce when the map becomes idle.
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pinAnim = CurvedAnimation(
      parent: _pinController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── Map lifecycle ────────────────────────────────────────────────────────
  void _onMapCreated(mbx.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Hide default compass / scale bar to match driver app style.
    mapboxMap.compass.updateSettings(mbx.CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(mbx.ScaleBarSettings(enabled: false));
    // Reduce scroll/pan sensitivity by adjusting gesture settings
    mapboxMap.gestures.updateSettings(
      mbx.GesturesSettings(
        pinchToZoomEnabled: true,
        pinchToZoomDecelerationEnabled: true,
        rotateEnabled: false,
        rotateDecelerationEnabled: false,
        pitchEnabled: false,
        quickZoomEnabled: true,
        doubleTapToZoomInEnabled: true,
        scrollEnabled: true,
        scrollDecelerationEnabled: true,
      ),
    );
  }

  void _onStyleLoaded(mbx.StyleLoadedEventData _) {
    // Trigger an initial reverse geocode so the input is populated right away.
    _reverseGeocode();
  }

  /// Fires continuously while the camera is moving (finger dragging).
  void _onCameraChangeListener(mbx.CameraChangedEventData _) {
    if (!_isDragging) {
      setState(() => _isDragging = true);
      // Pin lifts up immediately — no bounce while moving.
      _pinController.stop();
    }
  }

  /// Fires once when the camera settles after a gesture.
  Future<void> _onMapIdleListener(mbx.MapIdleEventData _) async {
    if (_isDragging) {
      setState(() => _isDragging = false);
      // Trigger the elastic drop animation.
      _pinController.forward(from: 0);
    }
    await _reverseGeocode();
  }

  // ── Reverse geocoding ────────────────────────────────────────────────────
  Future<void> _reverseGeocode() async {
    if (_mapboxMap == null) return;

    final state = await _mapboxMap!.getCameraState();
    final coords = state.center.coordinates;
    final lon = coords.lng.toDouble();
    final lat = coords.lat.toDouble();

    // Check if within Tunisia bounding box
    final inCoverage = isInTunisia(lat, lon);

    if (!mounted) return;
    setState(() {
      _currentLat = lat;
      _currentLon = lon;
      _isLoadingAddress = true;
      _isOutOfCoverage = !inCoverage;
    });

    if (inCoverage) {
      final place = await svc.MapboxService.reverseGeocode(lat, lon);
      if (!mounted) return;
      setState(() {
        _isLoadingAddress = false;
        _addressController.text = place?.fullAddress ?? '';
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoadingAddress = false;
        _addressController.text = '';
      });
    }
  }

  // ── Confirm ──────────────────────────────────────────────────────────────
  void _handleConfirm() {
    // Return ONLY lat/lon - backend will handle reverse geocoding for display name
    Navigator.of(context).pop<Map<String, dynamic>>({
      'latitude': _currentLat,
      'longitude': _currentLon,
    });
  }

  // ── Current location ──────────────────────────────────────────────────────
  Future<void> _handleCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        _mapboxMap?.flyTo(
          mbx.CameraOptions(
            center: mbx.Point(
              coordinates: mbx.Position(position.longitude, position.latitude),
            ),
            zoom: 16.0,
            bearing: 0.0, // Ensure north-up orientation
            pitch: 0.0,
          ),
          mbx.MapAnimationOptions(duration: 800),
        );
      }
    } catch (e) {
      // Handle permission denied or location errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get current location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────
          Positioned.fill(
            child: mbx.MapWidget(
              styleUri: isDark
                  ? mbx.MapboxStyles.DARK
                  : mbx.MapboxStyles.MAPBOX_STREETS,
              cameraOptions: mbx.CameraOptions(
                center: mbx.Point(
                  coordinates: mbx.Position(_defaultLon, _defaultLat),
                ),
                zoom: 14.0,
                bearing: 0.0, // Fix upside-down orientation (north-up)
                pitch: 0.0,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              onCameraChangeListener: _onCameraChangeListener,
              onMapIdleListener: _onMapIdleListener,
            ),
          ),

          // ── Top bar: back button + search input ───────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                BackBtn(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(
                  child: SearchInput(
                    addressController: _addressController,
                    isLoading: _isLoadingAddress,
                    isOutOfCoverage: _isOutOfCoverage,
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed centre pin (Flutter widget, not a map marker) ────────
          Center(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pinAnim,
                builder: (context, child) {
                  // While dragging the pin is lifted by a fixed offset.
                  // When the gesture ends the controller plays an elastic
                  // drop; the animation value (1 → 0 → 1 via elasticOut)
                  // simulates the bounce back to the resting position.
                  final liftedDy = _isDragging ? -12.0 : 0.0;
                  // Combine lift with the elastic settle value.
                  final bounceDy = _isDragging
                      ? -12.0
                      : (1 - _pinAnim.value) * -12.0;
                  return Transform.translate(
                    offset: Offset(0, liftedDy + (bounceDy - liftedDy)),
                    child: child,
                  );
                },
                child: const CenterPin(),
              ),
            ),
          ),

          // ── Bottom sheet ───────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: PickerBottomSheet(
              confirmLabel: widget.confirmLabel,
              addressController: _addressController,
              isLoading: _isLoadingAddress,
              isOutOfCoverage: _isOutOfCoverage,
              onConfirm:
                  _addressController.text.trim().isEmpty || _isOutOfCoverage
                  ? null
                  : _handleConfirm,
            ),
          ),

          // ── Current location button (bottom-right, above bottom sheet card) ──
          Positioned(
            right: 16,
            bottom:
                260, // Position above the compact bottom sheet card with clear gap
            child: LocationBtn(
              isLoading: _isLoadingLocation,
              onTap: _handleCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
}
