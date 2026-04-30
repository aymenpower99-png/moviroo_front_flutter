import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../utils/map_painters.dart';

/// Manager for map annotations (markers, polylines).
class MapAnnotationManager {
  mbx.PointAnnotationManager? _pointAnnotationManager;
  mbx.PolylineAnnotationManager? _lineAnnotationManager;
  bool _routeDrawn = false;

  /// Initialize annotation managers.
  Future<void> initialize(mbx.MapboxMap mapController) async {
    _pointAnnotationManager = await mapController.annotations
        .createPointAnnotationManager();
    _lineAnnotationManager = await mapController.annotations
        .createPolylineAnnotationManager();
  }

  /// Create pickup and dropoff markers.
  Future<void> initializeMarkers(mbx.Point pickup, mbx.Point dropoff) async {
    if (_pointAnnotationManager == null) return;

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

  /// Draw route polyline between pickup and dropoff.
  Future<void> drawRoute(
    mbx.Point pickup,
    mbx.Point dropoff,
    VoidCallback? onRouteDrawn,
  ) async {
    if (_routeDrawn || _lineAnnotationManager == null) return;
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

  /// Clear the route polyline.
  Future<void> clearRoute() async {
    if (_lineAnnotationManager != null) {
      await _lineAnnotationManager!.deleteAll();
      _routeDrawn = false;
    }
  }
}
