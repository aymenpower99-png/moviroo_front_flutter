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

extension RidePhaseSerialization on RidePhase {
  String toJson() => name;

  static RidePhase fromJson(String? value) {
    switch (value) {
      case 'driverArrived':
        return RidePhase.driverArrived;
      case 'rideInProgress':
        return RidePhase.rideInProgress;
      case 'rideEnded':
        return RidePhase.rideEnded;
      case 'driverOnTheWay':
      default:
        return RidePhase.driverOnTheWay;
    }
  }
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
  final String driverPhotoUrl;
  final String driverPhoneNumber;

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
    this.driverPhotoUrl = '',
    this.driverPhoneNumber = '',
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
    String? driverPhotoUrl,
    String? driverPhoneNumber,
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
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverPhoneNumber: driverPhoneNumber ?? this.driverPhoneNumber,
    );
  }

  // ── JSON serialization (for RideTrackingCache persistence) ─────────────

  Map<String, dynamic> toJson() => {
    'phase': phase.toJson(),
    'progress': progress,
    'etaMins': etaMins,
    'arrivalTime': arrivalTime,
    'distanceLeft': distanceLeft,
    'driverName': driverName,
    'vehicleName': vehicleName,
    'vehicleColor': vehicleColor,
    'plateNumber': plateNumber,
    'pickupAddress': pickupAddress,
    'dropoffAddress': dropoffAddress,
    'driverPhotoUrl': driverPhotoUrl,
    'driverPhoneNumber': driverPhoneNumber,
  };

  factory RideState.fromJson(Map<String, dynamic> json) {
    return RideState(
      phase: RidePhaseSerialization.fromJson(json['phase'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      etaMins: (json['etaMins'] as num?)?.toInt() ?? 0,
      arrivalTime: json['arrivalTime'] as String? ?? '',
      distanceLeft: json['distanceLeft'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      vehicleName: json['vehicleName'] as String? ?? '',
      vehicleColor: json['vehicleColor'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      driverPhotoUrl: json['driverPhotoUrl'] as String? ?? '',
      driverPhoneNumber: json['driverPhoneNumber'] as String? ?? '',
    );
  }
}
