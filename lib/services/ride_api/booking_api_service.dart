import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

/// Service for ride/booking-related API operations.
/// Talks to the backend `rides` controller (POST /rides, PATCH /rides/:id/confirm, etc.).
class BookingApiService {
  /// Create a new ride (booking) with status PENDING.
  /// Returns the ride object if successful (includes id, status, etc.).
  Future<Map<String, dynamic>?> createRide({
    required double pickupLat,
    required double pickupLon,
    required double dropoffLat,
    required double dropoffLon,
    String? pickupAddress,
    String? dropoffAddress,
    String? classId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Backend expects ISO-8601 datetime in `scheduled_at`. Default to now + 5 min if not given.
      DateTime scheduledAt;
      if (scheduledDate != null && scheduledTime != null) {
        scheduledAt = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
      } else {
        scheduledAt = DateTime.now().add(const Duration(minutes: 5));
      }

      final body = <String, dynamic>{
        'pickup_lat': pickupLat,
        'pickup_lon': pickupLon,
        'dropoff_lat': dropoffLat,
        'dropoff_lon': dropoffLon,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (classId != null) 'class_id': classId,
        if (pickupAddress != null && pickupAddress.isNotEmpty)
          'pickup_address': pickupAddress,
        if (dropoffAddress != null && dropoffAddress.isNotEmpty)
          'dropoff_address': dropoffAddress,
      };

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/rides'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create ride: ${response.body}');
    } catch (e) {
      throw Exception('Error creating ride: $e');
    }
  }

  /// Confirm a ride (locks price and triggers dispatch).
  /// Backend route: PATCH /rides/:id/confirm
  Future<Map<String, dynamic>?> confirmRide(String rideId) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}/rides/$rideId/confirm'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to confirm ride: ${response.body}');
    } catch (e) {
      throw Exception('Error confirming ride: $e');
    }
  }

  /// Cancel a ride.
  /// Backend route: PATCH /rides/:id/cancel
  Future<bool> cancelRide(String rideId, {String? reason}) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = <String, dynamic>{};
      if (reason != null) {
        body['cancellation_reason'] = reason;
      }

      final response = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}/rides/$rideId/cancel'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error cancelling ride: $e');
    }
  }

  /// Fetch all rides for the current user (passenger sees own; driver sees assigned; admin sees all).
  /// Backend route: GET /rides
  Future<List<Map<String, dynamic>>> getMyRides() async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/rides'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        return const [];
      }
      throw Exception('Failed to fetch rides: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching rides: $e');
    }
  }

  /// Get ride details by id.
  /// Backend route: GET /rides/:id
  Future<Map<String, dynamic>?> getRideDetails(String rideId) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/rides/$rideId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Non-critical — caller handles null
    }
    return null;
  }
}
