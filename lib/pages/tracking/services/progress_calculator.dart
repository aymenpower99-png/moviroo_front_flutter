import '../models/ride_state.dart';

/// Service for calculating and updating ride progress based on WebSocket events.
/// Extracts progress data from backend WebSocket events and updates RideState.
class ProgressCalculator {
  /// Update RideState with progress data from WebSocket location_update event
  ///
  /// The backend sends progress data in trip:location_update:
  /// - progress (0.0-1.0)
  /// - remainingDistanceMeters
  /// - etaMins
  RideState updateProgressFromWebSocket(
    RideState currentState,
    Map<String, dynamic> locationData,
  ) {
    // Extract progress data from WebSocket payload
    final progress = locationData['progress'] as double?;
    final remainingDistanceMeters =
        locationData['remainingDistanceMeters'] as num?;
    final etaMins = locationData['etaMins'] as int?;

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

    // Calculate arrival time from ETA
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
