import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Utility functions for camera operations on the map.
class MapCameraUtils {
  /// Fit camera bounds to center of route (simplified).
  static void fitBoundsToRoute(
    mbx.MapboxMap mapController,
    mbx.Point pickup,
    mbx.Point dropoff,
  ) {
    final center = mbx.Point(
      coordinates: mbx.Position(
        (pickup.coordinates.lng + dropoff.coordinates.lng) / 2,
        (pickup.coordinates.lat + dropoff.coordinates.lat) / 2,
      ),
    );
    mapController.setCamera(
      mbx.CameraOptions(center: center, zoom: 15.0, bearing: 0.0, pitch: 0.0),
    );
  }

  /// Fit camera bounds to include both pickup and dropoff with padding.
  static void fitBoundsToPickupAndDropoff(
    mbx.MapboxMap mapController,
    mbx.Point pickup,
    mbx.Point dropoff,
  ) {
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
    mapController
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
          (cam) => mapController.flyTo(
            cam,
            mbx.MapAnimationOptions(duration: 800),
          ),
        )
        .catchError((_) {});
  }

  /// Animate camera to a target point with optional bearing.
  static void animateCamera(
    mbx.MapboxMap mapController,
    mbx.Point target, {
    double bearing = 0,
  }) {
    mapController.flyTo(
      mbx.CameraOptions(
        center: target,
        zoom: 16.0,
        bearing: bearing,
        pitch: 0.0,
      ),
      mbx.MapAnimationOptions(duration: 600),
    );
  }
}
