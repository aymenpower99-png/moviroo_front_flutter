import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MapboxPlace {
  final String id;
  final String placeName;
  final String fullAddress;
  final IconData categoryIcon;
  final double? latitude;
  final double? longitude;

  MapboxPlace({
    required this.id,
    required this.placeName,
    required this.fullAddress,
    required this.categoryIcon,
    this.latitude,
    this.longitude,
  });

  factory MapboxPlace.fromJson(Map<String, dynamic> json) {
    final placeName = json['place_name'] as String? ?? '';
    final fullAddress = json['place_name'] as String? ?? '';
    final center = json['center'] as List?;
    final context = json['context'] as List?;
    final properties = json['properties'] as Map<String, dynamic>?;
    final placeType = json['place_type'] as List?;
    final featureName = json['text'] as String? ?? '';

    // ── Collect every available signal ───────────────────────────────────
    final List<String> signals = [];

    if (properties != null) {
      // category can be comma-separated: "hotel, lodging"
      final cat = properties['category'] as String? ?? '';
      if (cat.isNotEmpty) signals.addAll(cat.split(',').map((s) => s.trim()));

      final type = properties['type'] as String? ?? '';
      if (type.isNotEmpty) signals.add(type.trim());

      // maki is Mapbox's own semantic icon slug – very reliable when present
      final maki = properties['maki'] as String? ?? '';
      if (maki.isNotEmpty) signals.add(maki.trim());
    }

    if (placeType != null) {
      for (final t in placeType) {
        if (t is String && t.isNotEmpty) signals.add(t.trim());
      }
    }

    if (context != null) {
      for (final item in context) {
        if (item is Map<String, dynamic>) {
          final ctxId = item['id'] as String? ?? '';
          if (ctxId.startsWith('category.')) {
            signals.add(ctxId.replaceFirst('category.', '').trim());
          }
        }
      }
    }

    // ── Smart name-based fallback (critical for Tunisia's sparse POI data) ─
    // Always add the human-readable name so keyword rules can fire even when
    // Mapbox returns no category metadata at all.
    signals.add(featureName.toLowerCase());
    signals.add(placeName.toLowerCase());

    return MapboxPlace(
      id: json['id'] as String? ?? '',
      placeName: placeName,
      fullAddress: fullAddress,
      categoryIcon: _resolveIcon(signals),
      latitude: center != null && center.length >= 2
          ? (center[1] as num).toDouble()
          : null,
      longitude: center != null && center.length >= 2
          ? (center[0] as num).toDouble()
          : null,
    );
  }

  // ── Icon resolution ───────────────────────────────────────────────────
  // Rules are checked in order; first match wins.
  // Keywords are matched as substrings so "hotelx", "grand hotel", etc. all hit.
  static IconData _resolveIcon(List<String> signals) {
    // Build one lowercase string from all signals for easy substring search
    final combined = signals.join(' ').toLowerCase();

    // ── Lodging (name-based fallback is the key fix for Tunisia) ─────────
    if (_has(combined, ['hotel', 'lodging', 'motel', 'hostel',
        'guesthouse', 'guest_house', 'riad', 'resort', 'auberge'])) {
      return Icons.hotel;
    }

    // ── Food & drink ──────────────────────────────────────────────────────
    if (_has(combined, ['restaurant', 'eatery', 'diner', 'brasserie',
        'rotisserie', 'grill'])) {
      return Icons.restaurant;
    }
    if (_has(combined, ['cafe', 'café', 'coffee', 'tearoom', 'salon de thé'])) {
      return Icons.coffee;
    }
    if (_has(combined, ['bakery', 'boulangerie', 'pastry', 'patisserie',
        'pâtisserie'])) {
      return Icons.bakery_dining;
    }
    if (_has(combined, ['bar', 'pub', 'nightclub', 'lounge'])) {
      return Icons.local_bar;
    }
    if (_has(combined, ['fast_food', 'fastfood', 'fast food',
        'burger', 'sandwich', 'pizza'])) {
      return Icons.fastfood;
    }
    if (_has(combined, ['ice_cream', 'icecream', 'ice cream', 'glace'])) {
      return Icons.icecream;
    }

    // ── Transport ─────────────────────────────────────────────────────────
    if (_has(combined, ['airport', 'aerodrome', 'aéroport'])) {
      return Icons.flight;
    }
    if (_has(combined, ['train', 'station', 'gare', 'railway'])) {
      return Icons.train;
    }
    if (_has(combined, ['metro', 'subway'])) return Icons.subway;
    if (_has(combined, ['bus', 'autobus'])) return Icons.directions_bus;
    if (_has(combined, ['taxi', 'louage'])) return Icons.local_taxi;
    if (_has(combined, ['fuel', 'gas_station', 'petrol', 'station-service',
        'essence'])) {
      return Icons.local_gas_station;
    }
    if (_has(combined, ['parking'])) return Icons.local_parking;
    if (_has(combined, ['port', 'marina', 'harbour', 'harbor'])) {
      return Icons.directions_boat;
    }

    // ── Medical ───────────────────────────────────────────────────────────
    if (_has(combined, ['hospital', 'clinic', 'clinique', 'medical',
        'doctor', 'médecin', 'hopital', 'hôpital', 'polyclinique'])) {
      return Icons.local_hospital;
    }
    if (_has(combined, ['pharmacy', 'pharmacie', 'drugstore'])) {
      return Icons.medication;
    }

    // ── Education ─────────────────────────────────────────────────────────
    if (_has(combined, ['school', 'école', 'university', 'université',
        'college', 'collège', 'lycée', 'lycee', 'kindergarten',
        'maternelle', 'institut'])) {
      return Icons.school;
    }
    if (_has(combined, ['library', 'bibliothèque', 'bibliotheque'])) {
      return Icons.local_library;
    }

    // ── Shopping ──────────────────────────────────────────────────────────
    if (_has(combined, ['mall', 'centre commercial', 'shopping'])) {
      return Icons.shopping_bag;
    }
    if (_has(combined, ['supermarket', 'supermarché', 'supermarche',
        'grocery', 'épicerie', 'epicerie', 'marché', 'marche',
        'market'])) {
      return Icons.shopping_cart;
    }
    if (_has(combined, ['shop', 'store', 'boutique', 'magasin'])) {
      return Icons.storefront;
    }

    // ── Entertainment ─────────────────────────────────────────────────────
    if (_has(combined, ['cinema', 'movie', 'film'])) return Icons.movie;
    if (_has(combined, ['theater', 'theatre', 'théâtre'])) {
      return Icons.theater_comedy;
    }
    if (_has(combined, ['museum', 'musée', 'musee', 'gallery', 'galerie'])) {
      return Icons.museum;
    }
    if (_has(combined, ['stadium', 'stade', 'arena'])) return Icons.stadium;
    if (_has(combined, ['attraction', 'amusement', 'parc', 'theme park'])) {
      return Icons.attractions;
    }
    if (_has(combined, ['zoo'])) return Icons.pets;
    if (_has(combined, ['aquarium'])) return Icons.water;

    // ── Finance ───────────────────────────────────────────────────────────
    if (_has(combined, ['bank', 'banque', 'atm', 'guichet'])) {
      return Icons.account_balance;
    }

    // ── Government & services ─────────────────────────────────────────────
    if (_has(combined, ['post_office', 'poste', 'la poste'])) {
      return Icons.local_post_office;
    }
    if (_has(combined, ['police', 'commissariat', 'gendarmerie'])) {
      return Icons.local_police;
    }
    if (_has(combined, ['fire_station', 'pompiers'])) {
      return Icons.local_fire_department;
    }
    if (_has(combined, ['embassy', 'ambassade', 'consulat', 'consulate',
        'government', 'gouvernement', 'municipalité', 'municipalite',
        'mairie'])) {
      return Icons.account_balance;
    }

    // ── Nature & recreation ───────────────────────────────────────────────
    if (_has(combined, ['beach', 'plage'])) return Icons.beach_access;
    if (_has(combined, ['park', 'parc', 'jardin', 'garden'])) return Icons.park;
    if (_has(combined, ['camping', 'campground'])) return Icons.terrain;
    if (_has(combined, ['hiking', 'randonnée', 'randonnee'])) return Icons.hiking;
    if (_has(combined, ['golf'])) return Icons.sports_golf;
    if (_has(combined, ['gym', 'fitness', 'salle de sport'])) {
      return Icons.fitness_center;
    }
    if (_has(combined, ['spa', 'hammam', 'thalasso'])) return Icons.spa;
    if (_has(combined, ['sport'])) return Icons.sports;

    // ── Religious ─────────────────────────────────────────────────────────
    if (_has(combined, ['mosque', 'mosquée', 'mosquee', 'masjid', 'جامع'])) {
      return Icons.mosque;
    }
    if (_has(combined, ['church', 'église', 'eglise', 'cathedral',
        'cathédrale'])) {
      return Icons.church;
    }
    if (_has(combined, ['synagogue'])) return Icons.synagogue;
    if (_has(combined, ['temple', 'shrine'])) return Icons.temple_buddhist;

    // ── Absolute fallback ─────────────────────────────────────────────────
    return Icons.location_on;
  }

  /// Returns true if [text] contains any of the [keywords] as a substring.
  static bool _has(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));
}

// ── Service ───────────────────────────────────────────────────────────────

class MapboxService {
  static const String _accessToken =
      'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA';
  static const String _baseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  // Tunis city center
  static const double _proximityLng = 10.1815;
  static const double _proximityLat = 36.8065;

  /// Search for places using Mapbox Geocoding API
  static Future<List<MapboxPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json',
      ).replace(
        queryParameters: {
          'access_token': _accessToken,
          'autocomplete': 'true',
          'limit': '10',
          // Broader type list so POIs stored as place/address/locality
          // are not filtered out (critical for Tunisia's sparse POI dataset)
          'types': 'poi,address,place,locality,neighborhood,region',
          'country': 'tn',
          'proximity': '$_proximityLng,$_proximityLat',
          'language': 'en',
        },
      );

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
        debugPrint(
            'Mapbox search HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('Mapbox search error: $e\n$st');
    }

    return [];
  }

  /// Reverse geocode coordinates to address
  static Future<MapboxPlace?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/$longitude,$latitude.json').replace(
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