enum RideStatus { upcoming, completed, cancelled, pendingPayment }

enum RideTab { upcoming, completed, cancelled }

class RideModel {
  final String vehicleType;
  final String vehicleIcon;
  final String date;   // e.g. 'Today' or 'Oct 26'
  final String time;   // e.g. '18:30'
  final String vehicleName;
  final double price;
  final String pickup;
  final String dropoff;
  final RideStatus status;

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
  });
}