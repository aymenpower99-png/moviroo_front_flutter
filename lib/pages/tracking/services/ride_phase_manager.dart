/// Utility helper for ride-related calculations.
/// Phase transitions are now handled by WebSocket events from driver only.
class RidePhaseManager {
  String calcArrivalTime(int etaMins) {
    final arrival = DateTime.now().add(Duration(minutes: etaMins));
    return '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
  }
}
