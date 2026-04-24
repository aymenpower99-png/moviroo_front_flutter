import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mapbox_place.dart';

class MapboxService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _reverseUrl =
      'https://nominatim.openstreetmap.org/reverse';
static final Map<String, List<MapboxPlace>> _cache = {};
  static Future<List<MapboxPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    // ── Return cached result instantly (no API call) ──
    if (_cache.containsKey(query.toLowerCase())) {
      debugPrint('✅ Cache hit: $query');
      return _cache[query.toLowerCase()]!;
    }

    try {
      final url = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'countrycodes': 'tn',
          'limit': '10',
          'addressdetails': '1',
          'extratags': '1',
          'namedetails': '1',
        },
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'moviroo-app/1.0', 'Accept-Language': 'en'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data
            .map((item) => _fromNominatim(item as Map<String, dynamic>))
            .toList();

        // ── Save to cache ──
        _cache[query.toLowerCase()] = results;
        return results;
      } else if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limit - returning empty');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
    }

    return [];
  }

  static Future<MapboxPlace?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(_reverseUrl).replace(
        queryParameters: {
          'lat': '$latitude',
          'lon': '$longitude',
          'format': 'json',
          'addressdetails': '1',
          'extratags': '1',
        },
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'moviroo-app/1.0', 'Accept-Language': 'en'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _fromNominatim(data);
      }
    } catch (e, st) {
      debugPrint('Nominatim reverse geocode error: $e\n$st');
    }

    return null;
  }

  static MapboxPlace _fromNominatim(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final displayName = json['display_name'] as String? ?? '';
    final lat = double.tryParse(json['lat'] as String? ?? '');
    final lon = double.tryParse(json['lon'] as String? ?? '');
    final cls = json['class'] as String? ?? '';
    final type = json['type'] as String? ?? '';
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final extratags = json['extratags'] as Map<String, dynamic>? ?? {};

    final placeName = name.isNotEmpty ? name : _buildName(address);
    final shortAddress = _buildShortAddress(address);

    final List<String> signals = [
      cls,
      type,
      name.toLowerCase(),
      displayName.toLowerCase(),
      extratags['tourism'] as String? ?? '',
      extratags['amenity'] as String? ?? '',
      extratags['aeroway'] as String? ?? '',
      extratags['shop'] as String? ?? '',
      extratags['sport'] as String? ?? '',
      address['tourism'] as String? ?? '',
      address['amenity'] as String? ?? '',
      address['aeroway'] as String? ?? '',
    ];

    return MapboxPlace(
      id: '${json['place_id'] ?? json['osm_id'] ?? displayName}',
      placeName: placeName,
      fullAddress: shortAddress,
      categoryIcon: _resolveIcon(signals, cls, type),
      latitude: lat,
      longitude: lon,
    );
  }

  static String _buildName(Map<String, dynamic> address) {
    return address['tourism'] as String? ??
        address['amenity'] as String? ??
        address['building'] as String? ??
        address['road'] as String? ??
        address['suburb'] as String? ??
        address['city'] as String? ??
        '';
  }

  static String _buildShortAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    final road = address['road'] as String?;
    final suburb = address['suburb'] as String?;
    final city = address['city'] as String?;
    final state = address['state'] as String?;

    if (road != null && road.isNotEmpty) parts.add(road);
    if (suburb != null && suburb.isNotEmpty && suburb != road)
      parts.add(suburb);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty && state != city) parts.add(state);
    parts.add('Tunisia');

    return parts.join(', ');
  }

  static IconData _resolveIcon(List<String> signals, String cls, String type) {
    final combined = signals.join(' ').toLowerCase();

    if (cls == 'aeroway' ||
        type == 'aerodrome' ||
        _has(combined, [
          'airport',
          'aerodrome',
          'aéroport',
          'carthage international',
          'enfidha',
        ])) {
      return Icons.flight;
    }
    if (type == 'hotel' ||
        _has(combined, [
          'hotel',
          'hôtel',
          'motel',
          'hostel',
          'riad',
          'resort',
          'auberge',
          'guesthouse',
        ])) {
      return Icons.hotel;
    }
    if (type == 'restaurant' ||
        _has(combined, ['restaurant', 'brasserie', 'grill', 'pizzeria'])) {
      return Icons.restaurant;
    }
    if (type == 'cafe' ||
        _has(combined, ['cafe', 'café', 'coffee', 'patisserie'])) {
      return Icons.coffee;
    }
    if (type == 'fast_food' ||
        _has(combined, ['fast_food', 'burger', 'sandwich', 'kebab'])) {
      return Icons.fastfood;
    }
    if (type == 'bar' ||
        type == 'pub' ||
        _has(combined, ['bar', 'pub', 'nightclub'])) {
      return Icons.local_bar;
    }
    if (type == 'supermarket' ||
        _has(combined, ['supermarket', 'grocery', 'marché'])) {
      return Icons.shopping_cart;
    }
    if (type == 'mall' ||
        _has(combined, ['mall', 'centre commercial', 'shopping'])) {
      return Icons.shopping_bag;
    }
    if (cls == 'shop' || _has(combined, ['shop', 'store', 'boutique'])) {
      return Icons.storefront;
    }
    if (type == 'hospital' ||
        type == 'clinic' ||
        _has(combined, ['hospital', 'clinic', 'hôpital', 'polyclinique'])) {
      return Icons.local_hospital;
    }
    if (type == 'pharmacy' || _has(combined, ['pharmacy', 'pharmacie'])) {
      return Icons.medication;
    }
    if (type == 'school' ||
        type == 'university' ||
        _has(combined, ['school', 'université', 'lycée', 'institut'])) {
      return Icons.school;
    }
    if (type == 'bank' ||
        type == 'atm' ||
        _has(combined, ['bank', 'banque', 'atm'])) {
      return Icons.account_balance;
    }
    if (type == 'fuel' || _has(combined, ['fuel', 'petrol', 'essence'])) {
      return Icons.local_gas_station;
    }
    if (type == 'parking' || _has(combined, ['parking'])) {
      return Icons.local_parking;
    }
    if (cls == 'railway' ||
        type == 'station' ||
        _has(combined, ['gare', 'railway'])) {
      return Icons.train;
    }
    if (type == 'bus_station' || _has(combined, ['bus', 'autobus'])) {
      return Icons.directions_bus;
    }
    if (_has(combined, ['taxi', 'louage'])) return Icons.local_taxi;
    if (type == 'beach' || _has(combined, ['beach', 'plage']))
      return Icons.beach_access;
    if (type == 'park' || _has(combined, ['park', 'parc', 'jardin']))
      return Icons.park;
    if (type == 'museum' || _has(combined, ['museum', 'musée']))
      return Icons.museum;
    if (type == 'mosque' || _has(combined, ['mosque', 'mosquée', 'masjid']))
      return Icons.mosque;
    if (type == 'spa' || _has(combined, ['spa', 'hammam', 'thalasso']))
      return Icons.spa;
    if (type == 'police' || _has(combined, ['police', 'commissariat']))
      return Icons.local_police;
    if (cls == 'place' && _has(type, ['city', 'town', 'village', 'suburb'])) {
      return Icons.location_city;
    }
    if (cls == 'highway') return Icons.edit_road;

    return Icons.location_on;
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));
}
