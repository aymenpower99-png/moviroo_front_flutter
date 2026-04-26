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
  final int? etaMins;

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

  /// Build a [RideModel] from the JSON shape returned by `GET /rides`.
  /// Backend uses camelCase property names on the entity (TypeORM serialises
  /// to JSON with the entity property names, e.g. `pickupAddress`, `priceFinal`).
  factory RideModel.fromJson(Map<String, dynamic> json) {
    final backendStatus =
        (json['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final RideStatus status = _mapStatus(backendStatus);

    final vehicleClass = json['vehicleClass'] as Map<String, dynamic>?;
    final className = vehicleClass?['name'] as String? ?? 'Standard';

    final scheduledRaw =
        json['scheduledAt'] as String? ?? json['createdAt'] as String?;
    final scheduledDt = scheduledRaw != null
        ? DateTime.tryParse(scheduledRaw)
        : null;

    final priceFinal = _toDouble(json['priceFinal']);
    final priceEstimate = _toDouble(json['priceEstimate']);
    final price = priceFinal ?? priceEstimate ?? 0.0;

    final driver = json['driver'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;

    return RideModel(
      vehicleType: className,
      vehicleIcon: _iconFromClass(className),
      date: scheduledDt != null ? _formatDate(scheduledDt) : '—',
      time: scheduledDt != null ? _formatTime(scheduledDt) : '—',
      vehicleName: vehicle?['model'] as String? ?? className,
      price: price,
      pickup: json['pickupAddress'] as String? ?? '',
      dropoff: json['dropoffAddress'] as String? ?? '',
      status: status,
      rideId: json['id'] as String?,
      pickupLat: _toDouble(json['pickupLat']),
      pickupLon: _toDouble(json['pickupLon']),
      dropoffLat: _toDouble(json['dropoffLat']),
      dropoffLon: _toDouble(json['dropoffLon']),
      driverName: driver != null
          ? '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'.trim()
          : null,
      vehicleColor: vehicle?['color'] as String?,
      plateNumber: vehicle?['plateNumber'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Map backend `RideStatus` enum to the 3-bucket UI taxonomy.
  static RideStatus _mapStatus(String backend) {
    switch (backend) {
      case 'PENDING':
      case 'SEARCHING_DRIVER':
      case 'ASSIGNED':
      case 'EN_ROUTE_TO_PICKUP':
      case 'ARRIVED':
      case 'IN_TRIP':
        return RideStatus.upcoming;
      case 'COMPLETED':
        return RideStatus.completed;
      case 'CANCELLED':
        return RideStatus.cancelled;
      default:
        return RideStatus.upcoming;
    }
  }

  static String _iconFromClass(String name) {
    final n = name.toLowerCase();
    if (n.contains('premium') || n.contains('lux')) return 'sedan';
    if (n.contains('suv') || n.contains('xl')) return 'suv';
    return 'economy';
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
