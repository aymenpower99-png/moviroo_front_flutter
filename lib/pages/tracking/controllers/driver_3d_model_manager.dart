import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Manager for 3D driver car model on the map.
///
/// **Lifecycle contract:**
/// 1. Call [setupLayer] once after the map style is loaded, passing the
///    cached driver position. This creates the layer + source synchronously.
/// 2. Call [updatePosition] repeatedly on every animation tick or WebSocket
///    update. It only mutates the GeoJSON source — fast and lightweight.
/// 3. Never call [updatePosition] before [setupLayer]; it will buffer the
///    position and apply it immediately when the layer becomes ready.
class Driver3DModelManager {
  mbx.MapboxMap? _mapController;
  bool _driver3DModelReady = false;
  double _currentZoom = 13.0;

  // Position received before the layer was ready — applied immediately on setup.
  mbx.Point? _pendingPosition;
  double _pendingBearing = 0;

  // 3D model setup synchronization (prevents duplicate layers)
  Future<void>? _setupFuture;

  // Native style update throttling (matches animation tick rate)
  int _lastNativeUpdateMs = 0;
  static const int _minNativeUpdateIntervalMs = 16; // ~60 FPS cap

  // Model orientation calibration — GLB models typically face +Y or -Z axis,
  // so we rotate 180° to align the front of the car with the bearing direction.
  static const double _modelHeadingOffset = 180.0;

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

  /// Check if 3D model layer exists.
  bool get isReady => _driver3DModelReady;

  /// Create the 3D car model layer + source **once**.
  ///
  /// Call this from [onStyleLoaded] with the **cached** driver position so
  /// the car is visible instantly on warm start, before any WebSocket
  /// message arrives.
  ///
  /// Returns a [Future] that completes when the native layer is created.
  /// Safe to call multiple times — second and later calls are no-ops.
  Future<void> setupLayer(mbx.Point initialPos) {
    if (_mapController == null || _driver3DModelReady) return Future.value();
    return _setupFuture ??= _doSetup(initialPos);
  }

  Future<void> _doSetup(mbx.Point initialPos) async {
    debugPrint('🚗 [3D] Setting up 3D driver model layer...');

    try {
      // Clean up any existing layer/source — best-effort remove without
      // expensive async exists checks (~20-30ms saved per call).
      try {
        await _mapController!.style.removeStyleLayer('driver-model-layer');
      } catch (_) {}
      try {
        await _mapController!.style.removeStyleSource('driver-source');
      } catch (_) {}

      // Register the 3D model
      await _mapController!.style.addStyleModel(
        'driver-car',
        'asset://flutter_assets/images/3d/car.glb',
      );

      // Determine the initial position: if a pending update arrived before
      // the layer was ready, use it (it's newer than the cached value).
      final pos = _pendingPosition ?? initialPos;

      // Add GeoJSON source with driver position
      final geoJson = jsonEncode({
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

      // If we buffered a newer position while the layer was being created,
      // apply it now so the car doesn't sit on the cached position.
      if (_pendingPosition != null) {
        final pending = _pendingPosition!;
        final pendingB = _pendingBearing;
        _pendingPosition = null;
        _pendingBearing = 0;
        await _applyPosition(pending, pendingB);
      }
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

    const baseScale = 4.0; // Scale at zoom 18 (street level)
    const baseZoom = 18.0;
    const minScale = 1.0;
    const maxScale = 800.0;

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
  ///
  /// **Fast path:** only mutates the GeoJSON source string. Never triggers
  /// [setupLayer]. If the layer is not ready yet, the position is buffered
  /// and applied as soon as the layer is created.
  Future<void> updatePosition(
    mbx.Point pos,
    double bearing,
    Function(mbx.Point, double)? onDriverMarkerUpdated,
  ) async {
    if (_mapController == null) return;

    // Buffer updates that arrive before the layer is ready.
    // On cold start onStyleLoaded() skipped setup because driverPos was null.
    // We must trigger creation now so the car actually appears.
    if (!_driver3DModelReady) {
      _pendingPosition = pos;
      _pendingBearing = bearing;
      // Still notify the callback so state updates (driverPos, bearing) happen
      onDriverMarkerUpdated?.call(pos, bearing);
      // Kick off layer creation. If the style isn't ready yet this will
      // fail gracefully, reset _setupFuture, and onStyleLoaded() will retry.
      setupLayer(pos);
      return;
    }

    // Throttle to ~60 FPS cap
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNativeUpdateMs < _minNativeUpdateIntervalMs) {
      onDriverMarkerUpdated?.call(pos, bearing);
      return;
    }
    _lastNativeUpdateMs = now;

    await _applyPosition(pos, bearing);
    onDriverMarkerUpdated?.call(pos, bearing);
  }

  /// Internal: apply position to the native layer.
  Future<void> _applyPosition(mbx.Point pos, double bearing) async {
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
  }
}
