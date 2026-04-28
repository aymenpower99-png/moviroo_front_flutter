import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../utils/map_painters.dart';

/// Controller for map operations in tracking page.
/// Handles map initialization, marker management, route drawing, and camera updates.
class TrackingMapController {
  mbx.MapboxMap? _mapController;
  bool _routeDrawn = false;
  mbx.PointAnnotationManager? _pointAnnotationManager;
  mbx.PolylineAnnotationManager? _lineAnnotationManager;
  mbx.PointAnnotationOptions? _driverAnnotation;
  mbx.Point? _driverPos;
  double _driverBearing = 0;

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

  Future<void> updateDriverMarker(mbx.Point pos, double bearing) async {
    if (_mapController == null || _pointAnnotationManager == null) return;

    _driverPos = pos;
    _driverBearing = bearing;

    // Mapbox doesn't have a simple update - we need to delete and recreate
    // For now, just create/update the annotation
    if (_driverAnnotation == null) {
      _driverAnnotation = mbx.PointAnnotationOptions(
        geometry: pos,
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.CENTER,
        iconRotate: bearing,
      );
      await _pointAnnotationManager!.create(_driverAnnotation!);
    } else {
      // Update the annotation options and call update
      _driverAnnotation = mbx.PointAnnotationOptions(
        geometry: pos,
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.CENTER,
        iconRotate: bearing,
      );
      // Mapbox update requires passing the updated options
      await _pointAnnotationManager!.update(
        mbx.PointAnnotation(id: 'driver', geometry: pos, iconRotate: bearing),
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
      mbx.CameraOptions(center: center, zoom: 13.0, bearing: 0.0, pitch: 0.0),
    );
  }

  void animateCamera(mbx.Point target, {double bearing = 0}) {
    _mapController?.setCamera(
      mbx.CameraOptions(
        center: target,
        zoom: 15.0,
        bearing: bearing,
        pitch: 30.0,
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
