import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight synchronous cache for driver profiles used by passenger screens.
///
/// Keeps an in-memory map that survives for the app session and persists
/// to SharedPreferences so the cache survives backgrounding / restarts.
///
/// Usage:
///   DriverProfileCache.instance.set(driverId, {'logoUrl': url, 'name': name});
///   final profile = DriverProfileCache.instance.get(driverId);
class DriverProfileCache {
  static final DriverProfileCache _instance = DriverProfileCache._internal();
  factory DriverProfileCache() => _instance;
  DriverProfileCache._internal();
  static DriverProfileCache get instance => _instance;

  final Map<String, Map<String, dynamic>> _memory = {};
  bool _prefsReady = false;

  static const String _prefsKey = 'driver_profile_cache_v1';

  /// Ensure SharedPreferences are loaded. Call once at app startup.
  Future<void> init() async {
    if (_prefsReady) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>?;
        if (decoded != null) {
          _memory.clear();
          for (final entry in decoded.entries) {
            if (entry.value is Map<String, dynamic>) {
              _memory[entry.key] = Map<String, dynamic>.from(entry.value as Map);
            }
          }
        }
      }
      _prefsReady = true;
      debugPrint('✅ DriverProfileCache loaded ${_memory.length} profiles');
    } catch (e) {
      debugPrint('❌ DriverProfileCache init error: $e');
      _prefsReady = true;
    }
  }

  /// Store or update a driver profile. Writes through to disk.
  void set(String driverId, Map<String, dynamic> profile) {
    if (driverId.isEmpty) return;
    _memory[driverId] = Map<String, dynamic>.from(profile);
    _persist();
  }

  /// Get a profile synchronously. Returns null if unknown.
  Map<String, dynamic>? get(String driverId) {
    if (driverId.isEmpty) return null;
    return _memory[driverId];
  }

  /// Get the logo URL synchronously (common shortcut).
  String? getLogoUrl(String driverId) {
    final p = get(driverId);
    if (p == null) return null;
    return (p['logoUrl'] as String?) ??
        (p['logo_url'] as String?) ??
        (p['photoUrl'] as String?) ??
        (p['photo'] as String?) ??
        (p['avatarUrl'] as String?) ??
        (p['driverPhotoUrl'] as String?) ??
        (p['driver_logo_url'] as String?);
  }

  /// Pre-populate from ride list parsing without overwriting existing data.
  void preloadFromRideJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final driverId = driver?['id'] as String? ?? driver?['userId'] as String?;
    if (driverId == null || driverId.isEmpty) return;

    final existing = _memory[driverId] ?? {};
    final merged = Map<String, dynamic>.from(existing);

    // Copy common driver fields from the ride JSON
    final photoUrl =
        (driver?['logoUrl'] as String?) ??
        (driver?['logo_url'] as String?) ??
        (driver?['photoUrl'] as String?) ??
        (driver?['photo'] as String?) ??
        (driver?['avatarUrl'] as String?);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      merged['logoUrl'] = photoUrl;
    }
    final firstName = driver?['firstName'];
    if (firstName != null) merged['firstName'] = firstName;
    final lastName = driver?['lastName'];
    if (lastName != null) merged['lastName'] = lastName;
    final rating = driver?['ratingAverage'];
    if (rating != null) merged['ratingAverage'] = rating;

    _memory[driverId] = merged;
    _persist();
  }

  /// Pre-populate from a direct driver object.
  void preloadDriverProfile(Map<String, dynamic> driver) {
    final driverId = driver['id'] as String? ?? driver['userId'] as String?;
    if (driverId == null || driverId.isEmpty) return;

    final existing = _memory[driverId] ?? {};
    final merged = Map<String, dynamic>.from(existing);

    final photoUrl =
        (driver['logoUrl'] as String?) ??
        (driver['logo_url'] as String?) ??
        (driver['photoUrl'] as String?) ??
        (driver['photo'] as String?) ??
        (driver['avatarUrl'] as String?);

    if (photoUrl != null && photoUrl.isNotEmpty) merged['logoUrl'] = photoUrl;
    if (driver['firstName'] != null) merged['firstName'] = driver['firstName'];
    if (driver['lastName'] != null) merged['lastName'] = driver['lastName'];
    if (driver['ratingAverage'] != null) merged['ratingAverage'] = driver['ratingAverage'];

    _memory[driverId] = merged;
    _persist();
  }

  void _persist() {
    if (!_prefsReady) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, jsonEncode(_memory));
    }).catchError((e) {
      debugPrint('❌ DriverProfileCache persist error: $e');
    });
  }

  /// Clear everything (useful on logout).
  Future<void> clear() async {
    _memory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
