import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/tracking/models/ride_state.dart';

/// Persistent cache for live ride-tracking snapshots.
///
/// Allows the Track page to show the last known valid state immediately on
/// re-entry (warm start) instead of rendering broken intermediate state.
///
/// Each entry stores:
///   • a [RideState] snapshot
///   • the last driver position (lat/lon/bearing)
///   • the timestamp when the snapshot was saved
///
/// Usage:
///   RideTrackingCache.instance.set(rideId, state, lat, lon, bearing);
///   final snap = RideTrackingCache.instance.get(rideId);
class RideTrackingCache {
  static final RideTrackingCache _instance = RideTrackingCache._internal();
  factory RideTrackingCache() => _instance;
  RideTrackingCache._internal();
  static RideTrackingCache get instance => _instance;

  final Map<String, RideTrackingSnapshot> _memory = {};
  bool _prefsReady = false;

  static const String _prefsKey = 'ride_tracking_cache_v1';

  /// Maximum age of a cached snapshot before it is considered stale (minutes).
  static const int _maxAgeMin = 10;

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
            final snap = RideTrackingSnapshot.fromJson(
              entry.value as Map<String, dynamic>,
            );
            if (snap != null) _memory[entry.key] = snap;
          }
        }
      }
      _prefsReady = true;
      debugPrint(
        '✅ RideTrackingCache loaded ${_memory.length} snapshots',
      );
    } catch (e) {
      debugPrint('❌ RideTrackingCache init error: $e');
      _prefsReady = true;
    }
  }

  /// Store or update a snapshot for [rideId]. Writes through to disk.
  void set(
    String rideId,
    RideState state,
    double? driverLat,
    double? driverLon,
    double? driverBearing,
  ) {
    if (rideId.isEmpty) return;
    _memory[rideId] = RideTrackingSnapshot(
      rideState: state,
      driverLat: driverLat,
      driverLon: driverLon,
      driverBearing: driverBearing,
      savedAt: DateTime.now(),
    );
    _persist();
  }

  /// Retrieve the latest snapshot for [rideId].
  /// Returns `null` if missing or stale (> [_maxAgeMin] minutes old).
  RideTrackingSnapshot? get(String rideId) {
    if (rideId.isEmpty) return null;
    final snap = _memory[rideId];
    if (snap == null) return null;
    final ageMin = DateTime.now().difference(snap.savedAt).inMinutes;
    if (ageMin > _maxAgeMin) {
      debugPrint(
        '🗑️ RideTrackingCache: snapshot for $rideId stale (${ageMin}m), discarding',
      );
      _memory.remove(rideId);
      _persist();
      return null;
    }
    return snap;
  }

  /// Remove a snapshot (e.g. when a trip ends or is cancelled).
  void remove(String rideId) {
    if (_memory.remove(rideId) != null) _persist();
  }

  /// Clear everything (useful on logout).
  Future<void> clear() async {
    _memory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void _persist() {
    if (!_prefsReady) return;
    final payload = <String, dynamic>{};
    for (final e in _memory.entries) {
      payload[e.key] = e.value.toJson();
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, jsonEncode(payload));
    }).catchError((e) {
      debugPrint('❌ RideTrackingCache persist error: $e');
    });
  }
}

/// Snapshot of live tracking data stored by [RideTrackingCache].
class RideTrackingSnapshot {
  final RideState rideState;
  final double? driverLat;
  final double? driverLon;
  final double? driverBearing;
  final DateTime savedAt;

  RideTrackingSnapshot({
    required this.rideState,
    this.driverLat,
    this.driverLon,
    this.driverBearing,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'rideState': rideState.toJson(),
        'driverLat': driverLat,
        'driverLon': driverLon,
        'driverBearing': driverBearing,
        'savedAt': savedAt.toIso8601String(),
      };

  static RideTrackingSnapshot? fromJson(Map<String, dynamic> json) {
    try {
      final rideStateJson = json['rideState'] as Map<String, dynamic>?;
      if (rideStateJson == null) return null;
      return RideTrackingSnapshot(
        rideState: RideState.fromJson(rideStateJson),
        driverLat: (json['driverLat'] as num?)?.toDouble(),
        driverLon: (json['driverLon'] as num?)?.toDouble(),
        driverBearing: (json['driverBearing'] as num?)?.toDouble(),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
    } catch (e) {
      debugPrint('❌ RideTrackingCache snapshot parse error: $e');
      return null;
    }
  }
}
