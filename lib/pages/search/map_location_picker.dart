import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/mapbox_service.dart' as svc;

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
    final inCoverage = _isInTunisia(lat, lon);

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
        _addressController.text = place?.placeName ?? '';
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoadingAddress = false;
        _addressController.text = '';
      });
    }
  }

  /// Check if coordinates are within Tunisia's bounding box
  bool _isInTunisia(double lat, double lng) {
    return lat >= 30.2 && lat <= 37.5 && lng >= 7.5 && lng <= 11.6;
  }

  // ── Confirm ──────────────────────────────────────────────────────────────
  void _handleConfirm() {
    Navigator.of(context).pop<Map<String, dynamic>>({
      'address': _addressController.text,
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
    final t = AppLocalizations.of(context);

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

          // ── Back button (replaces removed top-right circular button) ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _BackBtn(onTap: () => Navigator.of(context).maybePop()),
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
                child: const _CenterPin(),
              ),
            ),
          ),

          // ── Current location button (bottom-right, above bottom sheet) ──
          Positioned(
            right: 16,
            bottom: 280, // Position above the bottom sheet
            child: _LocationBtn(
              isLoading: _isLoadingLocation,
              onTap: _handleCurrentLocation,
            ),
          ),

          // ── Bottom sheet ───────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomSheet(
              title: widget.title,
              subtitle: widget.subtitle,
              confirmLabel: widget.confirmLabel,
              addressController: _addressController,
              isLoading: _isLoadingAddress,
              isOutOfCoverage: _isOutOfCoverage,
              onConfirm:
                  _addressController.text.trim().isEmpty || _isOutOfCoverage
                  ? null
                  : _handleConfirm,
              localizations: t,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Centre pin (head + stem) ─────────────────────────────────────────────

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Head — filled circle (primary) with a white inner dot.
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryPurple,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
        // Stem — thin rounded rectangle beneath the head.
        Container(
          width: 4,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

// ─── Current location button ───────────────────────────────────────────────

class _LocationBtn extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LocationBtn({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPurple,
                  ),
                ),
              )
            : Icon(
                Icons.my_location_rounded,
                size: 22,
                color: AppColors.text(context),
              ),
      ),
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final TextEditingController addressController;
  final bool isLoading;
  final bool isOutOfCoverage;
  final VoidCallback? onConfirm;
  final AppLocalizations localizations;

  const _BottomSheet({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.addressController,
    required this.isLoading,
    required this.isOutOfCoverage,
    required this.onConfirm,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(title, style: AppTextStyles.pageTitle(context)),
            const SizedBox(height: 6),

            // Subtitle
            Text(subtitle, style: AppTextStyles.bodySmall(context)),
            const SizedBox(height: 24),

            // Location name row — clean text with dot, not a form field
            Row(
              children: [
                // Colored dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOutOfCoverage
                        ? AppColors.error
                        : AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 14),
                // Place name as plain text
                Expanded(
                  child: isLoading
                      ? Text(
                          'Locating…',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.subtext(context)),
                        )
                      : isOutOfCoverage
                      ? Text(
                          'Not available in this region yet',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.error),
                        )
                      : Text(
                          addressController.text.trim().isEmpty
                              ? 'Pin location'
                              : addressController.text,
                          style: AppTextStyles.bodyMedium(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Confirm button — uses AppTheme elevated button style
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfCoverage
                    ? AppColors.border(context)
                    : null, // Use default when enabled
                disabledBackgroundColor: AppColors.border(context),
              ),
              child: Text(
                confirmLabel,
                style: AppTextStyles.buttonPrimary.copyWith(
                  color: isOutOfCoverage ? AppColors.subtext(context) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
