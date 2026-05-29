import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../mapbox/mapbox_place.dart';

class GooglePlacesService {
  /// Search places using Google Places Autocomplete API (via backend)
  static Future<List<MapboxPlace>> searchPlaces(String query, {String? language}) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{'q': query};
      if (language != null && language.isNotEmpty) {
        params['lang'] = language;
      }

      final url = Uri.parse(
        '${AppConfig.baseUrl}/rides/geocode/google-search',
      ).replace(queryParameters: params);

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
          'Google search HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, st) {
      debugPrint('Google search error: $e\n$st');
    }

    return [];
  }
}
