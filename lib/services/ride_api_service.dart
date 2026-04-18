import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';

/// Fetches ride/trip data from the backend.
class RideApiService {
  Future<Map<String, dynamic>?> getTripStatus(String rideId) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/trips/$rideId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Non-critical — caller handles null
    }
    return null;
  }
}
