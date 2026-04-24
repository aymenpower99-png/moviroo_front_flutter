import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import '../../models/vehicle_pricing_response.dart';

class VehiclePricingService {
  Future<VehiclePricingResponse?> getVehiclePrices({
    required double pickupLat,
    required double pickupLon,
    required double dropoffLat,
    required double dropoffLon,
    String? bookingDt,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'pickupLat': pickupLat.toString(),
        'pickupLon': pickupLon.toString(),
        'dropoffLat': dropoffLat.toString(),
        'dropoffLon': dropoffLon.toString(),
        if (bookingDt != null) 'bookingDt': bookingDt,
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/rides/pricing',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return VehiclePricingResponse.fromJson(json);
      }
    } catch (e) {
      // Log error or handle silently
      print('Error fetching vehicle prices: $e');
    }
    return null;
  }
}
