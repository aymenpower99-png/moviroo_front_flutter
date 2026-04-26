import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

class GeocodingPlace {
  final String id;
  final String placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final String? source;
  final IconData categoryIcon;

  GeocodingPlace({
    required this.id,
    required this.placeName,
    this.address,
    required this.latitude,
    required this.longitude,
    this.source,
    IconData? categoryIcon,
  }) : categoryIcon = categoryIcon ?? Icons.location_on;

  factory GeocodingPlace.fromJson(Map<String, dynamic> json) {
    // Backend returns { lat, lon, display_name, city, country }
    // Also support frontend-style { latitude, longitude, place_name } for backwards compat
    final lat =
        (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        0.0;
    final lon =
        (json['longitude'] as num?)?.toDouble() ??
        (json['lon'] as num?)?.toDouble() ??
        0.0;
    final name =
        (json['place_name'] as String?) ??
        (json['display_name'] as String?) ??
        '';
    final addr = (json['address'] as String?) ?? (json['city'] as String?);

    return GeocodingPlace(
      id:
          json['id'] as String? ??
          json['place_id']?.toString() ??
          '${name}_${lat}_$lon',
      placeName: name,
      address: addr,
      latitude: lat,
      longitude: lon,
      source: json['source'] as String?,
      categoryIcon: _getDefaultIcon(json['source'] as String?),
    );
  }

  /// Returns true only if this place has valid (non-zero, in-range) coordinates
  bool get hasValidCoordinates {
    if (latitude == 0.0 && longitude == 0.0) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  /// Get full address (combines placeName and address)
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    return placeName;
  }

  static IconData _getDefaultIcon(String? source) {
    switch (source) {
      case 'mapbox':
        return Icons.location_city;
      case 'nominatim':
        return Icons.place;
      case 'gps':
        return Icons.my_location;
      case 'map_picker':
        return Icons.map;
      default:
        return Icons.location_on;
    }
  }
}

class GeocodingService {
  /// Search places using backend parallel search (Mapbox + Nominatim)
  Future<List<GeocodingPlace>> searchPlaces(String query) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/rides/geocode/search',
      ).replace(queryParameters: {'q': query});

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List;
        // Filter out places with invalid coordinates (e.g. 0,0 sea fallbacks)
        return json
            .map((e) => GeocodingPlace.fromJson(e as Map<String, dynamic>))
            .where((p) => p.hasValidCoordinates)
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
    return [];
  }
}
