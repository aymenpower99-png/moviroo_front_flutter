import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import '../../models/vehicle_pricing_response.dart';

class VehiclePricingService {
  // ── Static per-route TTL cache (3 min) ────────────────────────────────────

  static final Map<String, _PricingEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 3);

  static String _key(
    double lat1, double lon1, double lat2, double lon2, String? dt,
  ) {
    // Round to 4 decimal places (~11 m) so minor GPS jitter doesn't bust cache
    final k = '${lat1.toStringAsFixed(4)},${lon1.toStringAsFixed(4)},'
        '${lat2.toStringAsFixed(4)},${lon2.toStringAsFixed(4)}';
    // Truncate bookingDt to the minute so small time drift doesn't bust cache
    final d = dt != null && dt.length >= 16 ? dt.substring(0, 16) : (dt ?? '');
    return '$k,$d';
  }

  /// Get pricing for ALL active car classes from backend.
  /// Returns cached result instantly if the same route was fetched within 3 min.
  Future<VehiclePricingResponse?> getVehiclePrices({
    required double pickupLat,
    required double pickupLon,
    required double dropoffLat,
    required double dropoffLon,
    String? bookingDt,
  }) async {
    final key = _key(pickupLat, pickupLon, dropoffLat, dropoffLon, bookingDt);

    // Return cached if still fresh
    final entry = _cache[key];
    if (entry != null &&
        DateTime.now().difference(entry.fetchTime) < _cacheTtl) {
      return entry.response;
    }

    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{
        'pickupLat':  pickupLat.toString(),
        'pickupLon':  pickupLon.toString(),
        'dropoffLat': dropoffLat.toString(),
        'dropoffLon': dropoffLon.toString(),
        if (bookingDt != null) 'bookingDt': bookingDt,
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}/rides/pricing/all',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final response = VehiclePricingResponse.fromJson(json);
        _cache[key] = _PricingEntry(response);
        return response;
      }
    } catch (e) {
      debugPrint('Error fetching vehicle prices: $e');
    }
    return null;
  }
}

class _PricingEntry {
  final VehiclePricingResponse response;
  final DateTime fetchTime;
  _PricingEntry(this.response) : fetchTime = DateTime.now();
}

