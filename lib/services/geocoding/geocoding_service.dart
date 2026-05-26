import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/address_utils.dart';

/// Current app locale for address localization.
/// Updated by the app at startup and when locale changes.
String _currentAppLocale = 'fr';

void setAddressLocale(String locale) {
  _currentAppLocale = locale;
}

String get addressLocale => _currentAppLocale;

class GeocodingPlace {
  final String id;
  final String placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final String? source;
  final String? placeType;
  final String? category;
  final IconData categoryIcon;

  /// Raw display name from backend (unlocalized).
  final String rawPlaceName;

  /// Raw address from backend (unlocalized).
  final String? rawAddress;

  GeocodingPlace({
    required this.id,
    required this.placeName,
    required this.rawPlaceName,
    this.address,
    this.rawAddress,
    required this.latitude,
    required this.longitude,
    this.source,
    this.placeType,
    this.category,
    IconData? categoryIcon,
  }) : categoryIcon = categoryIcon ?? Icons.location_on;

  factory GeocodingPlace.fromJson(Map<String, dynamic> json) {
    // Backend returns { lat, lon, display_name, address, city, country, place_type, category }
    // Also support frontend-style { latitude, longitude, place_name } for backwards compat
    final lat =
        (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        0.0;
    final lon =
        (json['longitude'] as num?)?.toDouble() ??
        (json['lon'] as num?)?.toDouble() ??
        0.0;

    // Keep raw values for locale-aware display
    final rawName =
        (json['place_name'] as String?) ??
        (json['display_name'] as String?) ??
        (json['displayName'] as String?) ??
        '';
    final rawAddr = json['address'] as String?;

    // Apply basic cleanup (postal codes, country, admin labels)
    final name = simplifyAddress(rawName);
    final addr = rawAddr != null ? simplifyAddress(rawAddr) : null;

    final placeType = json['place_type'] as String?;
    final category = json['category'] as String?;

    return GeocodingPlace(
      id:
          json['id'] as String? ??
          json['place_id']?.toString() ??
          '${name}_${lat}_$lon',
      placeName: name,
      rawPlaceName: rawName,
      address: addr,
      rawAddress: rawAddr,
      latitude: lat,
      longitude: lon,
      source: json['source'] as String?,
      placeType: placeType,
      category: category,
      categoryIcon: _resolveIcon(category, placeType, json['source'] as String?),
    );
  }

  /// Returns a locale-aware display name.
  /// Uses the current app locale to filter mixed-language segments.
  String localizedPlaceName([String? locale]) {
    return buildLocalizedDisplayName(
      rawPlaceName,
      locale: locale ?? _currentAppLocale,
    );
  }

  /// Returns a locale-aware full address.
  String localizedFullAddress([String? locale]) {
    final raw = rawAddress ?? rawPlaceName;
    return buildLocalizedDisplayName(
      raw,
      locale: locale ?? _currentAppLocale,
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

  static IconData _resolveIcon(String? category, String? placeType, String? source) {
    final signals = <String>[];
    if (category != null && category.isNotEmpty) {
      signals.addAll(category.split(',').map((s) => s.trim().toLowerCase()));
    }
    if (placeType != null && placeType.isNotEmpty) {
      signals.addAll(placeType.split(',').map((s) => s.trim().toLowerCase()));
    }
    final combined = signals.join(' ');

    if (_has(combined, ['airport', 'aéroport', 'aeroport', 'aerodrome'])) return Icons.flight;
    if (_has(combined, ['hotel', 'hôtel', 'lodging', 'motel', 'hostel', 'guesthouse', 'guest_house', 'riad', 'resort', 'auberge', 'pension', 'villa'])) return Icons.hotel;
    if (_has(combined, ['restaurant', 'eatery', 'diner', 'brasserie', 'rotisserie', 'grill'])) return Icons.restaurant;
    if (_has(combined, ['cafe', 'café', 'coffee', 'tearoom', 'salon de thé'])) return Icons.coffee;
    if (_has(combined, ['bakery', 'boulangerie', 'pastry', 'patisserie', 'pâtisserie'])) return Icons.bakery_dining;
    if (_has(combined, ['bar', 'pub', 'nightclub', 'lounge'])) return Icons.local_bar;
    if (_has(combined, ['fast_food', 'fastfood', 'fast food', 'burger', 'sandwich', 'pizza'])) return Icons.fastfood;
    if (_has(combined, ['ice_cream', 'icecream', 'ice cream', 'glace'])) return Icons.icecream;
    if (_has(combined, ['train', 'station', 'gare', 'railway'])) return Icons.train;
    if (_has(combined, ['metro', 'subway'])) return Icons.subway;
    if (_has(combined, ['bus', 'autobus', 'gare routière', 'gare routiere'])) return Icons.directions_bus;
    if (_has(combined, ['taxi', 'louage'])) return Icons.local_taxi;
    if (_has(combined, ['fuel', 'gas_station', 'petrol', 'station-service', 'essence'])) return Icons.local_gas_station;
    if (_has(combined, ['parking'])) return Icons.local_parking;
    if (_has(combined, ['port', 'marina', 'harbour', 'harbor'])) return Icons.directions_boat;
    if (_has(combined, ['hospital', 'clinic', 'clinique', 'medical', 'doctor', 'médecin', 'hopital', 'hôpital', 'polyclinique'])) return Icons.local_hospital;
    if (_has(combined, ['pharmacy', 'pharmacie', 'drugstore'])) return Icons.medication;
    if (_has(combined, ['school', 'école', 'university', 'université', 'college', 'collège', 'lycée', 'lycee', 'kindergarten', 'maternelle', 'institut'])) return Icons.school;
    if (_has(combined, ['library', 'bibliothèque', 'bibliotheque'])) return Icons.local_library;
    if (_has(combined, ['mall', 'centre commercial', 'shopping'])) return Icons.shopping_bag;
    if (_has(combined, ['supermarket', 'supermarché', 'supermarche', 'grocery', 'épicerie', 'epicerie', 'marché', 'marche', 'market'])) return Icons.shopping_cart;
    if (_has(combined, ['shop', 'store', 'boutique', 'magasin'])) return Icons.storefront;
    if (_has(combined, ['cinema', 'movie', 'film'])) return Icons.movie;
    if (_has(combined, ['theater', 'theatre', 'théâtre'])) return Icons.theater_comedy;
    if (_has(combined, ['museum', 'musée', 'musee', 'gallery', 'galerie'])) return Icons.museum;
    if (_has(combined, ['stadium', 'stade', 'arena'])) return Icons.stadium;
    if (_has(combined, ['attraction', 'amusement', 'theme park'])) return Icons.attractions;
    if (_has(combined, ['zoo'])) return Icons.pets;
    if (_has(combined, ['aquarium'])) return Icons.water;
    if (_has(combined, ['bank', 'banque', 'atm', 'guichet'])) return Icons.account_balance;
    if (_has(combined, ['post_office', 'poste', 'la poste'])) return Icons.local_post_office;
    if (_has(combined, ['police', 'commissariat', 'gendarmerie'])) return Icons.local_police;
    if (_has(combined, ['fire_station', 'pompiers'])) return Icons.local_fire_department;
    if (_has(combined, ['embassy', 'ambassade', 'consulat', 'consulate', 'government', 'gouvernement', 'municipalité', 'municipalite', 'mairie'])) return Icons.account_balance;
    if (_has(combined, ['beach', 'plage'])) return Icons.beach_access;
    if (_has(combined, ['park', 'parc', 'jardin', 'garden'])) return Icons.park;
    if (_has(combined, ['camping', 'campground'])) return Icons.terrain;
    if (_has(combined, ['hiking', 'randonnée', 'randonnee'])) return Icons.hiking;
    if (_has(combined, ['golf'])) return Icons.sports_golf;
    if (_has(combined, ['gym', 'fitness', 'salle de sport'])) return Icons.fitness_center;
    if (_has(combined, ['spa', 'hammam', 'thalasso'])) return Icons.spa;
    if (_has(combined, ['sport'])) return Icons.sports;
    if (_has(combined, ['mosque', 'mosquée', 'mosquee', 'masjid'])) return Icons.mosque;
    if (_has(combined, ['church', 'église', 'eglise', 'cathedral', 'cathédrale'])) return Icons.church;
    if (_has(combined, ['synagogue'])) return Icons.synagogue;
    if (_has(combined, ['temple', 'shrine'])) return Icons.temple_buddhist;

    // Fallback to source-based generic icons
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

  static bool _has(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  GeocodingPlace copyWith({
    String? id,
    String? placeName,
    String? rawPlaceName,
    String? address,
    String? rawAddress,
    double? latitude,
    double? longitude,
    String? source,
    String? placeType,
    String? category,
    IconData? categoryIcon,
  }) {
    return GeocodingPlace(
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      rawPlaceName: rawPlaceName ?? this.rawPlaceName,
      address: address ?? this.address,
      rawAddress: rawAddress ?? this.rawAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      source: source ?? this.source,
      placeType: placeType ?? this.placeType,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }
}

class GeocodingService {
  /// Search places using backend parallel search (Mapbox + Nominatim)
  Future<List<GeocodingPlace>> searchPlaces(
    String query, {
    double? proximityLat,
    double? proximityLon,
    String? language,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final params = <String, String>{'q': query};
      if (proximityLat != null) {
        params['proximityLat'] = proximityLat.toString();
      }
      if (proximityLon != null) {
        params['proximityLon'] = proximityLon.toString();
      }
      if (language != null && language.isNotEmpty) {
        params['lang'] = language;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/rides/geocode/search',
      ).replace(queryParameters: params);

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

  /// Get nearby places from a given location (pickup)
  Future<List<GeocodingPlace>> getNearbyPlaces(
    double latitude,
    double longitude, {
    String? query,
    String? language,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      };
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (language != null && language.isNotEmpty) {
        queryParams['lang'] = language;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/rides/geocode/nearby',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List;
        return json
            .map((e) => GeocodingPlace.fromJson(e as Map<String, dynamic>))
            .where((p) => p.hasValidCoordinates)
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
    }
    return [];
  }

  /// Reverse geocode coordinates to place name
  static Future<GeocodingPlace?> reverseGeocode(
    double latitude,
    double longitude, {
    String? language,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final params = <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      };
      if (language != null && language.isNotEmpty) {
        params['lang'] = language;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}/rides/geocode/reverse')
          .replace(queryParameters: params);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return GeocodingPlace.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    return null;
  }
}
