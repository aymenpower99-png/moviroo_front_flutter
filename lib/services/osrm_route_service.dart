import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

/// Fetches real road routes from the OSRM demo server.
class OsrmRouteService {
  static Future<OsrmRouteResult?> fetchRoute(LatLng from, LatLng to) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?geometries=geojson&overview=full';

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route   = routes[0] as Map<String, dynamic>;
      final coords  = (route['geometry']['coordinates'] as List);
      final duration = (route['duration'] as num).toDouble();
      final distance = (route['distance'] as num).toDouble();

      final points = coords
          .map<LatLng>((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      return OsrmRouteResult(
        points: points,
        durationSeconds: duration,
        distanceMeters: distance,
      );
    } catch (_) {
      return null;
    }
  }
}

class OsrmRouteResult {
  final List<LatLng> points;
  final double durationSeconds;
  final double distanceMeters;

  const OsrmRouteResult({
    required this.points,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  String get etaText {
    final mins = (durationSeconds / 60).ceil();
    if (mins >= 60) {
      return '${mins ~/ 60}h ${mins % 60}min';
    }
    return '$mins min';
  }

  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toInt()} m';
  }
}
