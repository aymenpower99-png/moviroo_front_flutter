import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../geocoding/geocoding_service.dart';

class RecentSearchesService {
  static const String _pickupKey = 'recent_searches_pickup_v3';
  static const String _dropoffKey = 'recent_searches_dropoff_v3';
  static const String _oldPickupKey = 'recent_searches_pickup_v2';
  static const String _oldDropoffKey = 'recent_searches_dropoff_v2';
  static const int _maxRecentSearches = 3;

  /// Clear old v2 cache keys (pre-backend-API data)
  static Future<void> clearOldCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_oldPickupKey);
    await prefs.remove(_oldDropoffKey);
  }

  /// Get recent searches for pickup
  static Future<List<GeocodingPlace>> getPickupRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pickupKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => GeocodingPlace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent searches for dropoff
  static Future<List<GeocodingPlace>> getDropoffRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_dropoffKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => GeocodingPlace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a place to recent searches for pickup
  static Future<void> addPickupRecentSearch(GeocodingPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getPickupRecentSearches();

    final filtered = current.where((p) => p.id != place.id).toList();
    filtered.insert(0, place);
    final limited = filtered.take(_maxRecentSearches).toList();

    final jsonStr = jsonEncode(limited.map((p) => _encode(p)).toList());
    await prefs.setString(_pickupKey, jsonStr);
  }

  /// Add a place to recent searches for dropoff
  static Future<void> addDropoffRecentSearch(GeocodingPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDropoffRecentSearches();

    final filtered = current.where((p) => p.id != place.id).toList();
    filtered.insert(0, place);
    final limited = filtered.take(_maxRecentSearches).toList();

    final jsonStr = jsonEncode(limited.map((p) => _encode(p)).toList());
    await prefs.setString(_dropoffKey, jsonStr);
  }

  /// Clear all pickup recent searches
  static Future<void> clearPickupRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pickupKey);
  }

  /// Clear all dropoff recent searches
  static Future<void> clearDropoffRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dropoffKey);
  }

  // ── Encode GeocodingPlace → Map ─────────────
  static Map<String, dynamic> _encode(GeocodingPlace p) => {
    'id': p.id,
    'place_name': p.placeName,
    'address': p.address,
    'latitude': p.latitude,
    'longitude': p.longitude,
    'source': p.source,
  };
}
