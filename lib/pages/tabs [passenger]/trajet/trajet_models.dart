enum RideStatus { upcoming, completed, cancelled, pendingPayment }

enum RideTab { upcoming, completed, cancelled }

class RideModel {
  final String vehicleType;
  final String vehicleIcon;
  final String date;
  final String time;
  final String vehicleName;
  final double price;
  final String pickup;
  final String dropoff;
  final RideStatus status;

  // Tracking fields — populated when a driver is assigned
  final String? rideId;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final String? driverName;
  final String? vehicleColor;
  final String? plateNumber;
  final int?    etaMins;

  const RideModel({
    required this.vehicleType,
    required this.vehicleIcon,
    required this.date,
    required this.time,
    required this.vehicleName,
    required this.price,
    required this.pickup,
    required this.dropoff,
    required this.status,
    this.rideId,
    this.pickupLat,
    this.pickupLon,
    this.dropoffLat,
    this.dropoffLon,
    this.driverName,
    this.vehicleColor,
    this.plateNumber,
    this.etaMins,
  });
}