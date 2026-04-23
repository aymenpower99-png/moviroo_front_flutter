import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mapbox_service.dart';

class RecentSearchesService {
  static const String _pickupKey = 'recent_searches_pickup';
  static const String _dropoffKey = 'recent_searches_dropoff';
  static const int _maxRecentSearches = 3;

  /// Get recent searches for pickup
  static Future<List<MapboxPlace>> getPickupRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pickupKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
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
    final json = prefs.getString(_dropoffKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
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

    // Remove if already exists
    final filtered = current.where((p) => p.id != place.id).toList();

    // Add to beginning
    filtered.insert(0, place);

    // Keep only max items
    final limited = filtered.take(_maxRecentSearches).toList();

    final json = jsonEncode(limited.map((p) => {
      'id': p.id,
      'place_name': p.placeName,
      'full_address': p.fullAddress,
      'category_icon': p.categoryIcon,
      'latitude': p.latitude,
      'longitude': p.longitude,
    }).toList());

    await prefs.setString(_pickupKey, json);
  }

  /// Add a place to recent searches for dropoff
  static Future<void> addDropoffRecentSearch(MapboxPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDropoffRecentSearches();

    // Remove if already exists
    final filtered = current.where((p) => p.id != place.id).toList();

    // Add to beginning
    filtered.insert(0, place);

    // Keep only max items
    final limited = filtered.take(_maxRecentSearches).toList();

    final json = jsonEncode(limited.map((p) => {
      'id': p.id,
      'place_name': p.placeName,
      'full_address': p.fullAddress,
      'category_icon': p.categoryIcon,
      'latitude': p.latitude,
      'longitude': p.longitude,
    }).toList());

    await prefs.setString(_dropoffKey, json);
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
}
