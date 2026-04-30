import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Manager for 3D driver car model on the map.
class Driver3DModelManager {
  mbx.MapboxMap? _mapController;
  bool _driver3DModelReady = false;
  double _currentZoom = 13.0;

  // 3D model setup synchronization (prevents duplicate layers)
  Future<void>? _setupFuture;

  // Native style update throttling (prevents 60 FPS backpressure)
  int _lastNativeUpdateMs = 0;
  static const int _minNativeUpdateIntervalMs = 33; // ~30 FPS cap

  // Model orientation calibration
  static const double _modelHeadingOffset = 0.0;

  /// Set the map controller reference.
  void setMapController(mbx.MapboxMap mapController) {
    _mapController = mapController;
  }

  /// Update zoom level and recalculate scale to ensure visibility.
  void updateZoom(double zoom) {
    if (_currentZoom != zoom) {
      _currentZoom = zoom;
      _updateModelScale();
    }
  }

  /// Check if 3D model is ready.
  bool get isReady => _driver3DModelReady;

  /// Set up the 3D car model source + layer (call once after first location).
  Future<void> setup(mbx.Point initialPos) {
    if (_mapController == null || _driver3DModelReady) return Future.value();
    return _setupFuture ??= _doSetup(initialPos);
  }

  Future<void> _doSetup(mbx.Point initialPos) async {
    debugPrint('🚗 [3D] Setting up 3D driver model layer...');

    try {
      // Clean up any existing layer/source
      try {
        if (await _mapController!.style.styleLayerExists(
          'driver-model-layer',
        )) {
          await _mapController!.style.removeStyleLayer('driver-model-layer');
        }
        if (await _mapController!.style.styleSourceExists('driver-source')) {
          await _mapController!.style.removeStyleSource('driver-source');
        }
      } catch (_) {}

      // Register the 3D model
      await _mapController!.style.addStyleModel(
        'driver-car',
        'asset://flutter_assets/images/3d/car.glb',
      );

      // Add GeoJSON source with driver position
      final geoJson = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                initialPos.coordinates.lng.toDouble(),
                initialPos.coordinates.lat.toDouble(),
              ],
            },
            'properties': {},
          },
        ],
      });

      await _mapController!.style.addSource(
        mbx.GeoJsonSource(id: 'driver-source', data: geoJson),
      );

      // Add ModelLayer with initial scale (will be updated dynamically based on zoom)
      await _mapController!.style.addLayer(
        mbx.ModelLayer(
          id: 'driver-model-layer',
          sourceId: 'driver-source',
          modelScale: [4.0, 4.0, 4.0],
          modelRotation: [0, 0, _modelHeadingOffset],
          modelTranslation: [0, 0, 0],
          modelType: mbx.ModelType.COMMON_3D,
        ),
      );

      // Set model-id
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-id',
        'driver-car',
      );

      _driver3DModelReady = true;
      debugPrint('🚗 [3D] Setup COMPLETE');
    } catch (e) {
      debugPrint('🚗 [3D] ERROR: $e');
      _driver3DModelReady = false;
      _setupFuture = null;
    }
  }

  /// Update model scale based on zoom to ensure visibility at all levels.
  /// Uses exponential scaling that doubles scale per zoom level decrease.
  Future<void> _updateModelScale() async {
    if (!_driver3DModelReady || _mapController == null) return;

    // Exponential scaling: base scale at zoom 18, doubles per zoom level decrease
    // Zoom 18 (street): 4.0 (small)
    // Zoom 17: 8.0
    // Zoom 16: 16.0
    // Zoom 15: 32.0
    // Zoom 14: 64.0
    // Zoom 13: 128.0
    // Zoom 12: 256.0
    // Zoom 10: 1024.0 → clamped to 800.0
    // Zoom 5: 8192.0 → clamped to 800.0 (very visible at world view)
    const baseScale = 4.0; // Scale at zoom 18 (street level)
    const baseZoom = 18.0;
    const minScale = 1.0;
    const maxScale = 800.0;

    // Scale doubles when zoom decreases by 1 level
    final scale = (baseScale * math.pow(2.0, baseZoom - _currentZoom)).clamp(
      minScale,
      maxScale,
    );

    try {
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-scale',
        [scale, scale, scale],
      );
    } catch (e) {
      debugPrint('🚗 [3D] ERROR updating scale: $e');
    }
  }

  /// Update driver marker position and bearing.
  Future<void> updateDriverMarker(
    mbx.Point pos,
    double bearing,
    Function(mbx.Point, double)? onDriverMarkerUpdated,
  ) async {
    if (_mapController == null) return;

    if (!_driver3DModelReady) {
      await setup(pos);
      return;
    }

    // Throttle to ~30 FPS
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNativeUpdateMs < _minNativeUpdateIntervalMs) {
      onDriverMarkerUpdated?.call(pos, bearing);
      return;
    }
    _lastNativeUpdateMs = now;

    try {
      final newGeoJson = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                pos.coordinates.lng.toDouble(),
                pos.coordinates.lat.toDouble(),
              ],
            },
            'properties': {},
          },
        ],
      });

      final adjustedBearing = (bearing + _modelHeadingOffset) % 360;

      _mapController!.style.setStyleSourceProperty(
        'driver-source',
        'data',
        newGeoJson,
      );
      _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-rotation',
        [0, 0, adjustedBearing],
      );
    } catch (e) {
      debugPrint('🚗 [3D] ERROR updating: $e');
    }

    onDriverMarkerUpdated?.call(pos, bearing);
  }
}
