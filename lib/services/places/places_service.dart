import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

class Place {
  final String id;
  final String displayName;
  final String? address;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.displayName,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class PlacesService {
  /// Get nearby places based on coordinates
  Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radiusKm.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/places/nearby',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List;
        return json
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
    }
    return [];
  }

  /// Search places by name
  Future<List<Place>> searchPlaces({
    required String query,
    int limit = 20,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/places/search',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List;
        return json
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
    return [];
  }
}
