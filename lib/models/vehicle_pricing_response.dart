class VehicleClassPrice {
  final String id;
  final String name;
  final String? imageUrl;
  final int seats;
  final int bags;
  final int priceTnd;
  final double exactPrice;
  final double distanceKm;
  final int durationMin;
  final double surgeMultiplier;
  final int loyaltyPoints;

  VehicleClassPrice({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.seats,
    required this.bags,
    required this.priceTnd,
    required this.exactPrice,
    required this.distanceKm,
    required this.durationMin,
    required this.surgeMultiplier,
    required this.loyaltyPoints,
  });

  factory VehicleClassPrice.fromJson(Map<String, dynamic> json) {
    return VehicleClassPrice(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      seats: json['seats'] as int,
      bags: json['bags'] as int,
      priceTnd: json['priceTnd'] as int,
      exactPrice: (json['exactPrice'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMin: json['durationMin'] as int,
      surgeMultiplier: (json['surgeMultiplier'] as num).toDouble(),
      loyaltyPoints: json['loyaltyPoints'] as int,
    );
  }
}

class VehiclePricingResponse {
  final List<VehicleClassPrice> vehicleClasses;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;

  VehiclePricingResponse({
    required this.vehicleClasses,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
  });

  factory VehiclePricingResponse.fromJson(Map<String, dynamic> json) {
    final vehicleClassesList = (json['vehicleClasses'] as List<dynamic>)
        .map((e) => VehicleClassPrice.fromJson(e as Map<String, dynamic>))
        .toList();

    return VehiclePricingResponse(
      vehicleClasses: vehicleClassesList,
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLon: (json['pickupLon'] as num).toDouble(),
      dropoffLat: (json['dropoffLat'] as num).toDouble(),
      dropoffLon: (json['dropoffLon'] as num).toDouble(),
    );
  }
}
