import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../utils/map_painters.dart';

/// Controller for map operations in tracking page.
/// Handles map initialization, marker management, route drawing, and camera updates.
class TrackingMapController {
  mbx.MapboxMap? _mapController;
  bool _routeDrawn = false;
  mbx.PointAnnotationManager? _pointAnnotationManager;
  mbx.PolylineAnnotationManager? _lineAnnotationManager;
  mbx.Point? _driverPos;
  double _driverBearing = 0;
  bool _driver3DModelReady = false;
  double _currentZoom = 13.0;

  // ── 3D model setup synchronization (prevents duplicate layers) ─────────────
  Future<void>? _setupFuture;

  // ── Native style update throttling (prevents 60 FPS backpressure) ───────────
  int _lastNativeUpdateMs = 0;
  static const int _minNativeUpdateIntervalMs = 33; // ~30 FPS cap

  // ── Model orientation calibration ───────────────────────────────────────────
  static const double _modelHeadingOffset = 0.0;

  // Callbacks
  final Function(mbx.Point, double)? onDriverMarkerUpdated;
  final Function()? onRouteDrawn;

  TrackingMapController({this.onDriverMarkerUpdated, this.onRouteDrawn});

  mbx.MapboxMap? get controller => _mapController;
  bool get isReady => _mapController != null;
  mbx.Point? get driverPos => _driverPos;
  double get driverBearing => _driverBearing;

  void setMapController(mbx.MapboxMap controller) {
    _mapController = controller;
  }

  void updateZoom(double zoom) {
    if (_currentZoom != zoom) {
      _currentZoom = zoom;
      _updateModelScale();
    }
  }

  Future<void> initializeAnnotationManagers() async {
    if (_mapController == null) return;
    _pointAnnotationManager = await _mapController!.annotations
        .createPointAnnotationManager();
    _lineAnnotationManager = await _mapController!.annotations
        .createPolylineAnnotationManager();
  }

  Future<void> initializeMarkers(mbx.Point pickup, mbx.Point dropoff) async {
    if (_mapController == null || _pointAnnotationManager == null) return;

    // Pickup marker with custom icon
    await _pointAnnotationManager!.create(
      mbx.PointAnnotationOptions(
        geometry: pickup,
        image: await MapPainters.renderPickupBitmap(),
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.CENTER,
      ),
    );

    // Dropoff marker with custom icon
    await _pointAnnotationManager!.create(
      mbx.PointAnnotationOptions(
        geometry: dropoff,
        image: await MapPainters.renderDropoffBitmap(),
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.BOTTOM,
      ),
    );
  }

  Future<void> drawRoute(mbx.Point pickup, mbx.Point dropoff) async {
    if (_mapController == null ||
        _routeDrawn ||
        _lineAnnotationManager == null) {
      return;
    }
    _routeDrawn = true;

    // Straight-line fallback (no OSRM)
    await _lineAnnotationManager!.create(
      mbx.PolylineAnnotationOptions(
        geometry: mbx.LineString(
          coordinates: [pickup.coordinates, dropoff.coordinates],
        ),
        lineColor: 0xFFA855F7,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ),
    );
    onRouteDrawn?.call();
  }

  /// Set up the 3D car model source + layer (call once after first location).
  Future<void> _setup3DDriver(mbx.Point initialPos) {
    if (_mapController == null || _driver3DModelReady) return Future.value();
    return _setupFuture ??= _doSetup3DDriver(initialPos);
  }

  Future<void> _doSetup3DDriver(mbx.Point initialPos) async {
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

      // Add ModelLayer
      await _mapController!.style.addLayer(
        mbx.ModelLayer(
          id: 'driver-model-layer',
          sourceId: 'driver-source',
          modelScale: [6, 6, 6],
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
    } catch (e, st) {
      debugPrint('🚗 [3D] ERROR: $e');
      _driver3DModelReady = false;
      _setupFuture = null;
    }
  }

  Future<void> _updateModelScale() async {
    if (!_driver3DModelReady || _mapController == null) return;

    final scale = 0.5 * math.pow(2.0, _currentZoom - 15).clamp(0.3, 2.5);

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

  Future<void> updateDriverMarker(mbx.Point pos, double bearing) async {
    if (_mapController == null) return;

    _driverPos = pos;
    _driverBearing = bearing;

    if (!_driver3DModelReady) {
      await _setup3DDriver(pos);
      if (_driver3DModelReady) {
        await _updateModelScale();
      }
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

  double distanceMeters(mbx.Point from, mbx.Point to) {
    const earthRadius = 6371000.0;
    final lat1 = _rad(from.coordinates.lat.toDouble());
    final lat2 = _rad(to.coordinates.lat.toDouble());
    final dLat = lat2 - lat1;
    final dLon = _rad((to.coordinates.lng - from.coordinates.lng).toDouble());
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void fitBoundsToRoute(mbx.Point pickup, mbx.Point dropoff) {
    if (_mapController == null) return;
    final center = mbx.Point(
      coordinates: mbx.Position(
        (pickup.coordinates.lng + dropoff.coordinates.lng) / 2,
        (pickup.coordinates.lat + dropoff.coordinates.lat) / 2,
      ),
    );
    _mapController!.setCamera(
      mbx.CameraOptions(center: center, zoom: 15.0, bearing: 0.0, pitch: 0.0),
    );
  }

  void fitBoundsToPickupAndDropoff(mbx.Point pickup, mbx.Point dropoff) {
    if (_mapController == null) return;
    final swLat = math.min(
      pickup.coordinates.lat.toDouble(),
      dropoff.coordinates.lat.toDouble(),
    );
    final swLng = math.min(
      pickup.coordinates.lng.toDouble(),
      dropoff.coordinates.lng.toDouble(),
    );
    final neLat = math.max(
      pickup.coordinates.lat.toDouble(),
      dropoff.coordinates.lat.toDouble(),
    );
    final neLng = math.max(
      pickup.coordinates.lng.toDouble(),
      dropoff.coordinates.lng.toDouble(),
    );
    _mapController!
        .cameraForCoordinateBounds(
          mbx.CoordinateBounds(
            southwest: mbx.Point(coordinates: mbx.Position(swLng, swLat)),
            northeast: mbx.Point(coordinates: mbx.Position(neLng, neLat)),
            infiniteBounds: false,
          ),
          mbx.MbxEdgeInsets(top: 80, left: 80, bottom: 300, right: 80),
          null,
          null,
          null,
          null,
        )
        .then(
          (cam) => _mapController?.flyTo(
            cam,
            mbx.MapAnimationOptions(duration: 800),
          ),
        )
        .catchError((_) {});
  }

  void animateCamera(mbx.Point target, {double bearing = 0}) {
    _mapController?.flyTo(
      mbx.CameraOptions(
        center: target,
        zoom: 16.0,
        bearing: bearing,
        pitch: 0.0,
      ),
      mbx.MapAnimationOptions(duration: 600),
    );
  }

  double calcBearing(mbx.Point from, mbx.Point to) {
    final dLon = _rad((to.coordinates.lng - from.coordinates.lng).toDouble());
    final lat1 = _rad(from.coordinates.lat.toDouble());
    final lat2 = _rad(to.coordinates.lat.toDouble());
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  double _rad(double deg) => deg * math.pi / 180;
  double _deg(double rad) => rad * 180 / math.pi;
}
