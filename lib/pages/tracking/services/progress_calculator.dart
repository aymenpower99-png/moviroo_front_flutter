import '../models/ride_state.dart';

/// Service for calculating and updating ride progress based on WebSocket events.
/// Extracts progress data from backend WebSocket events and updates RideState.
class ProgressCalculator {
  /// Update RideState with progress data from WebSocket location_update event
  ///
  /// The backend sends progress data in trip:location_update:
  /// - progress (0.0-1.0)
  /// - remainingDistanceMeters
  /// - etaMins (already in MINUTES — computed by RoutingService)
  RideState updateProgressFromWebSocket(
    RideState currentState,
    Map<String, dynamic> locationData,
  ) {
    // Ignore progress updates once the driver has arrived — the UI is in
    // "arrived" mode and should not flip back to showing ETA / progress.
    if (currentState.phase == RidePhase.driverArrived) {
      return currentState;
    }

    // Extract progress data from WebSocket payload.
    // Use `as num?` then `.toDouble()` because JSON serialises whole-number
    // doubles (e.g. 1.0) as ints and `as double?` would silently fail.
    final progress = (locationData['progress'] as num?)?.toDouble();
    final remainingDistanceMeters =
        (locationData['remainingDistanceMeters'] as num?) ??
        (locationData['remaining_distance_m'] as num?) ??
        (locationData['distance_left_m'] as num?) ??
        (locationData['remaining_meters'] as num?);
    final rawEtaMins =
        (locationData['etaMins'] as num?)?.toInt() ??
        (locationData['driver_eta_min'] as num?)?.toInt() ??
        (locationData['eta_min'] as num?)?.toInt() ??
        (locationData['eta'] as num?)?.toInt();

    // Defensive cap: reject absurdly large values (> 3 hours) as bad data.
    final etaMins = (rawEtaMins != null && rawEtaMins > 180) ? null : rawEtaMins;

    // Convert remaining distance to string for display
    String distanceLeftText = currentState.distanceLeft;
    if (remainingDistanceMeters != null) {
      if (remainingDistanceMeters >= 1000) {
        distanceLeftText =
            '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
      } else {
        distanceLeftText = '${remainingDistanceMeters.toInt()} m';
      }
    }

    // Calculate arrival time from ETA (already in minutes)
    String arrivalTimeText = currentState.arrivalTime;
    if (etaMins != null) {
      final arrival = DateTime.now().add(Duration(minutes: etaMins));
      arrivalTimeText =
          '${arrival.hour.toString().padLeft(2, '0')}:'
          '${arrival.minute.toString().padLeft(2, '0')}';
    }

    // Update RideState with new progress data
    return currentState.copyWith(
      progress: progress ?? currentState.progress,
      etaMins: etaMins ?? currentState.etaMins,
      arrivalTime: arrivalTimeText,
      distanceLeft: distanceLeftText,
    );
  }
}
