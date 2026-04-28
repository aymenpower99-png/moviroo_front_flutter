/// Represents the four stages of a ride lifecycle.
enum RidePhase {
  /// Driver is on the way to the pickup location.
  driverOnTheWay,

  /// Driver has arrived at the pickup location.
  driverArrived,

  /// Passenger is in the car — trip in progress.
  rideInProgress,

  /// Trip has ended successfully.
  rideEnded,
}

/// Immutable snapshot of everything the Track-Ride screen needs.
class RideState {
  final RidePhase phase;

  /// 0.0 → 1.0. Driven by the caller; the UI just reads it.
  final double progress;

  final int etaMins;
  final String arrivalTime;
  final String distanceLeft;
  final String driverName;
  final String vehicleName;

  /// e.g. "White", "Black" — shown in the arrival card.
  final String vehicleColor;
  final String plateNumber;

  /// Pickup and drop-off addresses shown in the route card.
  final String pickupAddress;
  final String dropoffAddress;

  const RideState({
    required this.phase,
    required this.progress,
    required this.etaMins,
    required this.arrivalTime,
    required this.distanceLeft,
    required this.driverName,
    required this.vehicleName,
    this.vehicleColor = '',
    required this.plateNumber,
    this.pickupAddress = '',
    this.dropoffAddress = '',
  });

  RideState copyWith({
    RidePhase? phase,
    double? progress,
    int? etaMins,
    String? arrivalTime,
    String? distanceLeft,
    String? driverName,
    String? vehicleName,
    String? vehicleColor,
    String? plateNumber,
    String? pickupAddress,
    String? dropoffAddress,
  }) {
    return RideState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      etaMins: etaMins ?? this.etaMins,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      distanceLeft: distanceLeft ?? this.distanceLeft,
      driverName: driverName ?? this.driverName,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      plateNumber: plateNumber ?? this.plateNumber,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    );
  }
}
