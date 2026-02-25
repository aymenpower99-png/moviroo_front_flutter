enum RideStatus { upcoming, completed, cancelled }

enum RideTab { upcoming, completed, cancelled }

class RideModel {
  final String vehicleType;
  final String vehicleIcon; // asset or we use IconData
  final String date;
  final String vehicleName;
  final double price;
  final String pickup;
  final String dropoff;
  final RideStatus status;

  const RideModel({
    required this.vehicleType,
    required this.vehicleIcon,
    required this.date,
    required this.vehicleName,
    required this.price,
    required this.pickup,
    required this.dropoff,
    required this.status,
  });
}