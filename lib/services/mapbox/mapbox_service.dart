import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mapbox_place.dart';
import '../../core/config/app_config.dart';

class MapboxService {
  static const String _mapboxAccessToken =
      'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA';
  static const String _mapboxDirectionsUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Search places using backend unified autocomplete endpoint
  static Future<List<MapboxPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/rides/geocode/autocomplete',
      ).replace(queryParameters: {'q': query});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data
            .map(
              (item) => MapboxPlace.fromBackend(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint(
          'Backend autocomplete HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, st) {
      debugPrint('Backend autocomplete error: $e\n$st');
    }

    return [];
  }

  /// Reverse geocode using backend endpoint
  static Future<MapboxPlace?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/rides/geocode/reverse')
          .replace(
            queryParameters: {
              'lat': latitude.toString(),
              'lon': longitude.toString(),
            },
          );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return MapboxPlace.fromBackend(data);
      }
    } catch (e, st) {
      debugPrint('Backend reverse geocode error: $e\n$st');
    }

    return null;
  }

  /// Get route geometry from Mapbox Directions API
  static Future<List<double>> getRouteGeometry(
    double pickupLat,
    double pickupLon,
    double dropoffLat,
    double dropoffLon,
  ) async {
    debugPrint(
      '[MapboxService] getRouteGeometry called: pickup=($pickupLat, $pickupLon), dropoff=($dropoffLat, $dropoffLon)',
    );

    // Ensure coordinates are in valid range
    if (pickupLat.abs() > 90 ||
        pickupLon.abs() > 180 ||
        dropoffLat.abs() > 90 ||
        dropoffLon.abs() > 180) {
      debugPrint('[MapboxService] Coordinates out of range - using fallback');
      return [];
    }

    try {
      final url =
          Uri.parse(
            '$_mapboxDirectionsUrl/$pickupLon,$pickupLat;$dropoffLon,$dropoffLat',
          ).replace(
            queryParameters: {
              'access_token': _mapboxAccessToken,
              'geometries': 'geojson',
              'overview': 'full',
            },
          );

      debugPrint('[MapboxService] requesting: $url');
      final response = await http.get(url);
      debugPrint('[MapboxService] response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List;
        debugPrint('[MapboxService] routes count: ${routes.length}');
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          debugPrint('[MapboxService] coordinate count: ${coordinates.length}');

          // Flatten the coordinates array from [[lon, lat], [lon, lat], ...] to [lon, lat, lon, lat, ...]
          final flattened = <double>[];
          for (var coord in coordinates) {
            final c = coord as List;
            flattened.add(c[0] as double); // lon
            flattened.add(c[1] as double); // lat
          }
          debugPrint(
            '[MapboxService] returning ${flattened.length} flattened values',
          );
          return flattened;
        }
      } else {
        debugPrint('[MapboxService] non-200 response: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('Mapbox Directions API error: $e\n$st');
    }

    // Fallback to straight line if API fails
    debugPrint('[MapboxService] using fallback straight line');
    return [pickupLon, pickupLat, dropoffLon, dropoffLat];
  }
}
