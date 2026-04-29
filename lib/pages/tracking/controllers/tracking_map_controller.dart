import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../utils/map_painters.dart';

/// Controller for map operations in tracking page.
/// Handles map initialization, marker management, route drawing, and camera updates.
class TrackingMapController {
  mbx.MapboxMap? _mapController;
  bool _routeDrawn = false;
  mbx.PointAnnotationManager? _pointAnnotationManager;
  mbx.PolylineAnnotationManager? _lineAnnotationManager;
  mbx.PointAnnotation? _driverAnnotation;
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

  /// Set up the 3D car model source + layer (call once after style loaded).
  Future<void> _setup3DDriver(mbx.Point initialPos) async {
    if (_mapController == null || _driver3DModelReady) return;
    debugPrint('🚗 [3D] Setting up 3D driver model layer...');
    debugPrint(
      '🚗 [3D] Initial position: lat=${initialPos.coordinates.lat}, lng=${initialPos.coordinates.lng}',
    );

    try {
      // 1. Add GeoJSON source with the driver position
      debugPrint('🚗 [3D] Step 1: Adding GeoJSON source...');
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
      debugPrint('🚗 [3D] GeoJSON: $geoJson');

      await _mapController!.style.addSource(
        mbx.GeoJsonSource(id: 'driver-source', data: geoJson),
      );
      debugPrint('🚗 [3D] Step 1: GeoJSON source added ✓');

      // 2. Add ModelLayer — pass actual asset path to modelId
      //    SDK converts modelId via _getFlutterAssetPath, so
      //    'images/3d/car.glb' → 'asset://flutter_assets/images/3d/car.glb'
      debugPrint(
        '🚗 [3D] Step 2: Adding ModelLayer with modelId=images/3d/car.glb...',
      );
      debugPrint(
        '🚗 [3D] Layer config: scale=[50,50,50], rotation=[0,0,0], type=COMMON_3D',
      );
      await _mapController!.style.addLayer(
        mbx.ModelLayer(
          id: 'driver-model-layer',
          sourceId: 'driver-source',
          modelId: 'images/3d/car.glb',
          modelScale: [50, 50, 50],
          modelRotation: [0, 0, 0],
          modelType: mbx.ModelType.COMMON_3D,
        ),
      );
      debugPrint('🚗 [3D] Step 2: ModelLayer added ✓');

      _driver3DModelReady = true;
      debugPrint('🚗 [3D] Setup COMPLETE — 3D car should be visible now');
      debugPrint('🚗 [3D] Check if car.glb file exists at images/3d/car.glb');
    } catch (e, st) {
      debugPrint('🚗 [3D] ❌ ERROR: $e');
      debugPrint('🚗 [3D] Stack: $st');
      _driver3DModelReady = false;
    }
  }

  /// Update model scale based on zoom level (inversely proportional)
  Future<void> _updateModelScale() async {
    if (!_driver3DModelReady || _mapController == null) {
      debugPrint(
        '🚗 [3D] Skip scale update: 3D model ready=$_driver3DModelReady, controller exists=${_mapController != null}',
      );
      return;
    }

    final baseScale = 200.0;
    final scale = baseScale / _currentZoom;
    debugPrint(
      '🚗 [3D] Updating scale: base=$baseScale, zoom=$_currentZoom, result=$scale',
    );

    try {
      await _mapController!.style.setStyleLayerProperty(
        'driver-model-layer',
        'model-scale',
        [scale, scale, scale],
      );
      debugPrint('🚗 [3D] Scale updated successfully');
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
      debugPrint('🚗 [3D] 3D model not ready yet, setting up...');
      await _setup3DDriver(pos);
      debugPrint(
        '🚗 [3D] Setup returned, _driver3DModelReady=$_driver3DModelReady',
      );
      // Update scale for current zoom immediately
      if (_driver3DModelReady) {
        await _updateModelScale();
      }
    }

    if (!_driver3DModelReady) {
      debugPrint('🚗 [3D] ❌ 3D model failed to set up — will use 2D fallback');
    } else {
      debugPrint('🚗 [3D] 3D model ready, updating position and rotation...');
      try {
        // Update source position
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
        debugPrint('🚗 [3D] Updating GeoJSON source with new position');

        await _mapController!.style.setStyleSourceProperty(
          'driver-source',
          'data',
          newGeoJson,
        );
        debugPrint('🚗 [3D] Source position updated ✓');

        // Update rotation
        debugPrint('🚗 [3D] Updating rotation to bearing=$bearing');
        await _mapController!.style.setStyleLayerProperty(
          'driver-model-layer',
          'model-rotation',
          [0, 0, bearing],
        );
        debugPrint('🚗 [3D] Rotation updated ✓');
      } catch (e) {
        debugPrint('🚗 [3D] ERROR updating 3D model: $e');
      }
    }

    // Fallback: 2D car marker (show this if 3D model not visible)
    if (_pointAnnotationManager != null) {
      if (_driverAnnotation == null) {
        debugPrint('🗺️ Creating 2D car marker as fallback...');
        try {
          final bitmap = await MapPainters.renderCarBitmap();
          _driverAnnotation = await _pointAnnotationManager!.create(
            mbx.PointAnnotationOptions(
              geometry: pos,
              image: bitmap,
              iconSize: 0.4,
              iconAnchor: mbx.IconAnchor.CENTER,
              iconRotate: bearing,
            ),
          );
          debugPrint('🗺️ 2D car marker created (3D fallback)');
        } catch (e) {
          debugPrint('🗺️ ERROR creating 2D fallback: $e');
        }
      } else {
        debugPrint('🗺️ Updating 2D car marker...');
        _driverAnnotation!.geometry = pos;
        _driverAnnotation!.iconRotate = bearing;
        try {
          await _pointAnnotationManager!.update(_driverAnnotation!);
          debugPrint('🗺️ 2D car marker updated ✓');
        } catch (e) {
          debugPrint('🗺️ ERROR updating 2D fallback: $e');
        }
      }
    } else {
      debugPrint(
        '🗺️ 2D fallback not available: pointAnnotationManager is null',
      );
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
