import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mapbox/mapbox_place.dart';
import '../mapbox/mapbox_service.dart';

class RecentSearchesService {
  static const String _pickupKey = 'recent_searches_pickup';
  static const String _dropoffKey = 'recent_searches_dropoff';
  static const int _maxRecentSearches = 3;

  /// Get recent searches for pickup
  static Future<List<MapboxPlace>> getPickupRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pickupKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => MapboxPlace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent searches for dropoff
  static Future<List<MapboxPlace>> getDropoffRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_dropoffKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => MapboxPlace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a place to recent searches for pickup
  static Future<void> addPickupRecentSearch(MapboxPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getPickupRecentSearches();

    final filtered = current.where((p) => p.id != place.id).toList();
    filtered.insert(0, place);
    final limited = filtered.take(_maxRecentSearches).toList();

    final jsonStr = jsonEncode(limited.map((p) => _encode(p)).toList());
    await prefs.setString(_pickupKey, jsonStr);
  }

  /// Add a place to recent searches for dropoff
  static Future<void> addDropoffRecentSearch(MapboxPlace place) async {
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

  // ── Encode MapboxPlace → Map (IconData serialized safely) ─────────────
  static Map<String, dynamic> _encode(MapboxPlace p) => {
    'id': p.id,
    'place_name': p.placeName,
    'full_address': p.fullAddress,
    'icon_code_point': p.categoryIcon.codePoint,
    'icon_font_family': p.categoryIcon.fontFamily ?? 'MaterialIcons',
    'latitude': p.latitude,
    'longitude': p.longitude,
  };
}
