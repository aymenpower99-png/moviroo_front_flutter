import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mapbox_place.dart';

class MapboxService {
  static const String _accessToken =
      'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA';
  static const String _baseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  static const double _proximityLng = 10.1815;
  static const double _proximityLat = 36.8065;

  static const List<String> _noProximityKeywords = [
    'hotel', 'hôtel', 'lodging', 'motel', 'hostel',
    'guesthouse', 'riad', 'resort', 'auberge', 'dar ', 'pension',
    'airport', 'aéroport', 'aeroport', 'aerodrome',
    'carthage', 'enfidha', 'monastir', 'djerba', 'sfax', 'tabarka',
    'beach', 'plage', 'thalasso',
    'gare routière', 'gare routiere', 'louage',
  ];

  static bool _shouldSkipProximity(String query) {
    final lq = query.toLowerCase();
    return _noProximityKeywords.any((kw) => lq.contains(kw));
  }

  static Future<List<MapboxPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final skipProximity = _shouldSkipProximity(query);

    try {
      final Map<String, String> params = {
        'access_token': _accessToken,
        'autocomplete': 'true',
        'limit': '10',
        'fuzzyMatch': 'true',
        'types': 'poi,address,place,locality,neighborhood,region,district',
        'language': 'en',
      };

      if (skipProximity) {
        params['bbox'] = '7.5,30.2,11.6,37.5';
      } else {
        params['country'] = 'tn';
        params['proximity'] = '$_proximityLng,$_proximityLat';
      }

      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json',
      ).replace(queryParameters: params);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null) {
          return features
              .map((f) => MapboxPlace.fromJson(f as Map<String, dynamic>))
              .toList();
        }
      } else {
        debugPrint('Mapbox HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('Mapbox search error: $e\n$st');
    }

    return [];
  }

  static Future<MapboxPlace?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url =
          Uri.parse('$_baseUrl/$longitude,$latitude.json').replace(
        queryParameters: {
          'access_token': _accessToken,
          'types': 'poi,address,place,locality,neighborhood',
          'language': 'en',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          return MapboxPlace.fromJson(features.first as Map<String, dynamic>);
        }
      }
    } catch (e, st) {
      debugPrint('Mapbox reverse geocode error: $e\n$st');
    }

    return null;
  }
}