import 'package:flutter/foundation.dart';
import '../models/ride_state.dart';

/// Simple in-memory cache to keep the last known RideState per rideId so that
/// reopening the tracking screen paints instantly without re-fetch/flicker.
class RideTrackingCache {
  RideTrackingCache._();
  static final RideTrackingCache instance = RideTrackingCache._();

  final Map<String, RideState> _snapshots = {};
  final Map<String, DateTime> _snapshotAt = {};

  RideState? get(String rideId) => _snapshots[rideId];

  void set(String rideId, RideState state) {
    _snapshots[rideId] = state;
    _snapshotAt[rideId] = DateTime.now();
    debugPrint('🗂️ [RideTrackingCache] Snapshot set for $rideId at ${_snapshotAt[rideId]}');
  }

  bool has(String rideId) => _snapshots.containsKey(rideId);

  DateTime? snapshotTime(String rideId) => _snapshotAt[rideId];

  void remove(String rideId) {
    _snapshots.remove(rideId);
    _snapshotAt.remove(rideId);
  }
}
