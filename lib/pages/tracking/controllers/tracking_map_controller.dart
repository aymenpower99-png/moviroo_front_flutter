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
  Future<void> _setup3DDriver(mbx.Point initialPos) async {
    if (_mapController == null || _driver3DModelReady) return;
    debugPrint('🚗 [3D] Setting up 3D driver model layer...');
    debugPrint(
      '🚗 [3D] Initial position: lat=${initialPos.coordinates.lat}, lng=${initialPos.coordinates.lng}',
    );

    try {
      // 1. Register the 3D model in the style with full asset URI
      debugPrint('🚗 [3D] Step 1: Registering 3D model in style...');
      await _mapController!.style.addStyleModel(
        'driver-car',
        'asset://flutter_assets/images/3d/car2.glb',
      );
      debugPrint('🚗 [3D] Step 1: Model registered as driver-car ✓');

      // 2. Add GeoJSON source with the driver position
      debugPrint('🚗 [3D] Step 2: Adding GeoJSON source...');
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
      debugPrint('🚗 [3D] Step 2: GeoJSON source added ✓');

      // 3. Add ModelLayer WITHOUT modelId (avoid SDK path transform)
      debugPrint('🚗 [3D] Step 3: Adding ModelLayer...');
      await _mapController!.style.addLayer(
        mbx.ModelLayer(
          id: 'driver-model-layer',
          sourceId: 'driver-source',
          modelScale: [150, 150, 150],
          modelRotation: [0, 0, 0],
          modelType: mbx.ModelType.COMMON_3D,
        ),
      );
      debugPrint('🚗 [3D] Step 3: ModelLayer added ✓');

      // 4. Set model-id directly via style property (bypasses SDK path transform)
      debugPrint('🚗 [3D] Step 4: Setting model-id to driver-car...');
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-id',
        'driver-car',
      );
      debugPrint('🚗 [3D] Step 4: model-id set ✓');

      _driver3DModelReady = true;
      debugPrint('🚗 [3D] Setup COMPLETE — 3D car should be visible now');
    } catch (e, st) {
      debugPrint('🚗 [3D] ❌ ERROR setting up 3D model: $e');
      debugPrint('🚗 [3D] Stack: $st');
      _driver3DModelReady = false;
    }
  }

  /// Update model scale based on zoom level.
  /// Zoom in → bigger car, zoom out → smaller car.
  Future<void> _updateModelScale() async {
    if (!_driver3DModelReady || _mapController == null) return;

    // Exponential scaling: each zoom level doubles the visual size
    // At zoom 10 → scale ~5, zoom 13 → ~40, zoom 15 → ~150, zoom 17 → ~600
    final scale = 5.0 * math.pow(2, (_currentZoom - 10));
    debugPrint('🚗 [3D] Scale update: zoom=$_currentZoom, scale=$scale');

    try {
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-scale',
        [scale, scale, scale],
      );
    } catch (e) {
      debugPrint('🚗 [3D] ERROR updating model scale: $e');
    }
  }

  Future<void> updateDriverMarker(mbx.Point pos, double bearing) async {
    debugPrint(
      '🗺️ updateDriverMarker: lat=${pos.coordinates.lat}, lng=${pos.coordinates.lng}, bearing=$bearing',
    );

    if (_mapController == null) {
      debugPrint('🗺️ updateDriverMarker early return — controller not ready');
      return;
    }

    _driverPos = pos;
    _driverBearing = bearing;

    // Set up 3D model on first call
    if (!_driver3DModelReady) {
      debugPrint('🚗 [3D] First location — setting up driver model...');
      await _setup3DDriver(pos);
      debugPrint('🚗 [3D] Setup returned, ready=$_driver3DModelReady');
      if (_driver3DModelReady) {
        await _updateModelScale();
      }
      return; // first frame handled by setup
    }

    // Update 3D model position via GeoJSON source
    debugPrint('🚗 [3D] Updating 3D model position and rotation...');
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
      await _mapController!.style.setStyleSourceProperty(
        'driver-source',
        'data',
        newGeoJson,
      );
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-rotation',
        [0, 0, bearing],
      );
      debugPrint('🚗 [3D] Position & rotation updated ✓');
    } catch (e) {
      debugPrint('🚗 [3D] ERROR updating 3D model: $e');
    }

    onDriverMarkerUpdated?.call(pos, bearing);
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
      mbx.CameraOptions(center: center, zoom: 15.0, bearing: 0.0, pitch: 60.0),
    );
  }

  void animateCamera(mbx.Point target, {double bearing = 0}) {
    _mapController?.setCamera(
      mbx.CameraOptions(
        center: target,
        zoom: 16.0,
        bearing: bearing,
        pitch: 45.0,
      ),
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
