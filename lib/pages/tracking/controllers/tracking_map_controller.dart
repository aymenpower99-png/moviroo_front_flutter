import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import 'driver_3d_model_manager.dart';
import 'geo_utils.dart';
import 'map_annotation_manager.dart';
import 'map_camera_utils.dart';

/// Controller for map operations in tracking page.
/// Delegates to specialized helper classes for different responsibilities.
class TrackingMapController {
  mbx.MapboxMap? _mapController;
  mbx.Point? _driverPos;
  double _driverBearing = 0;

  // Helper managers
  final Driver3DModelManager _driverModelManager = Driver3DModelManager();
  final MapAnnotationManager _annotationManager = MapAnnotationManager();

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
    _driverModelManager.setMapController(controller);
  }

  void updateZoom(double zoom) {
    _driverModelManager.updateZoom(zoom);
  }

  Future<void> initializeAnnotationManagers() async {
    if (_mapController == null) return;
    await _annotationManager.initialize(_mapController!);
  }

  Future<void> initializeMarkers(mbx.Point pickup, mbx.Point dropoff) async {
    await _annotationManager.initializeMarkers(pickup, dropoff);
  }

  Future<void> drawRoute(mbx.Point pickup, mbx.Point dropoff) async {
    await _annotationManager.drawRoute(pickup, dropoff, onRouteDrawn);
  }

  Future<void> clearRoute() async {
    await _annotationManager.clearRoute();
  }

  Future<void> updateDriverMarker(mbx.Point pos, double bearing) async {
    if (_mapController == null) return;

    _driverPos = pos;
    _driverBearing = bearing;

    await _driverModelManager.updateDriverMarker(
      pos,
      bearing,
      onDriverMarkerUpdated,
    );
  }

  double distanceMeters(mbx.Point from, mbx.Point to) {
    return GeoUtils.distanceMeters(from, to);
  }

  void fitBoundsToRoute(mbx.Point pickup, mbx.Point dropoff) {
    if (_mapController == null) return;
    MapCameraUtils.fitBoundsToRoute(_mapController!, pickup, dropoff);
  }

  void fitBoundsToPickupAndDropoff(mbx.Point pickup, mbx.Point dropoff) {
    if (_mapController == null) return;
    MapCameraUtils.fitBoundsToPickupAndDropoff(
      _mapController!,
      pickup,
      dropoff,
    );
  }

  void animateCamera(mbx.Point target, {double bearing = 0}) {
    if (_mapController == null) return;
    MapCameraUtils.animateCamera(_mapController!, target, bearing: bearing);
  }

  double calcBearing(mbx.Point from, mbx.Point to) {
    return GeoUtils.calcBearing(from, to);
  }
}
