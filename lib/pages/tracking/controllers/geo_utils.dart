import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Pure utility functions for geographic calculations.
class GeoUtils {
  /// Calculate distance between two points in meters using Haversine formula.
  static double distanceMeters(mbx.Point from, mbx.Point to) {
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

  /// Calculate bearing from one point to another in degrees.
  static double calcBearing(mbx.Point from, mbx.Point to) {
    final dLon = _rad((to.coordinates.lng - from.coordinates.lng).toDouble());
    final lat1 = _rad(from.coordinates.lat.toDouble());
    final lat2 = _rad(to.coordinates.lat.toDouble());
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}
