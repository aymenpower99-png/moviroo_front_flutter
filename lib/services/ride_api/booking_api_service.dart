import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

/// Service for ride/booking-related API operations.
/// Talks to the backend `rides` controller (POST /rides, PATCH /rides/:id/confirm, etc.).
class BookingApiService {
  // ── In-memory cache for saved cards ─────────────────────────────────────────
  static List<Map<String, dynamic>>? _cachedSavedCards;

  List<Map<String, dynamic>>? get cachedSavedCards => _cachedSavedCards;
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
    String? couponCode,
    double? discountPercent,
    /// ML price + values locked at vehicle selection.
    /// Sent to backend so it reuses them directly without a second ML call.
    double? lockedPrice,
    int? lockedLoyaltyPoints,
    double? lockedDistanceKm,
    int? lockedDurationMin,
    double? lockedSurge,
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
        if (couponCode != null && couponCode.isNotEmpty)
          'coupon_code': couponCode,
        if (discountPercent != null && discountPercent > 0)
          'discount_percent': discountPercent,
        if (lockedPrice != null && lockedPrice > 0)
          'locked_price': lockedPrice,
        if (lockedLoyaltyPoints != null)
          'locked_loyalty_points': lockedLoyaltyPoints,
        if (lockedDistanceKm != null)
          'locked_distance_km': lockedDistanceKm,
        if (lockedDurationMin != null)
          'locked_duration_min': lockedDurationMin,
        if (lockedSurge != null)
          'locked_surge': lockedSurge,
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
  Future<Map<String, dynamic>?> confirmRide(String rideId, {String? paymentMethod}) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = <String, dynamic>{};
      if (paymentMethod != null) {
        body['paymentMethod'] = paymentMethod;
      }

      final response = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}/rides/$rideId/confirm'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      // 409 = already confirmed — treat as no-op so callers can safely retry
      if (response.statusCode == 409) {
        return null;
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

  /// Get or create a Stripe PaymentIntent for a CARD ride.
  /// Backend route: POST /billing/payments/ride/:rideId/stripe-intent
  /// Returns { clientSecret, paymentIntentId, customerId, ephemeralKey }.
  Future<Map<String, dynamic>> createStripeIntentForRide(String rideId) async {
    final token = await TokenStorage.getAccess();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          Uri.parse(
            '${AppConfig.baseUrl}/billing/payments/ride/$rideId/stripe-intent',
          ),
          headers: headers,
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create Stripe intent: ${response.body}');
  }

  /// Create a Stripe SetupIntent to add a card without charging.
  /// Backend route: POST /billing/setup-intent
  /// Returns { setupIntentClientSecret, customerId, ephemeralKey }.
  Future<Map<String, dynamic>> createSetupIntent() async {
    final token = await TokenStorage.getAccess();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/billing/setup-intent'),
          headers: headers,
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create setup intent: ${response.body}');
  }

  /// Fetch the passenger's saved cards from Stripe.
  /// Backend route: GET /billing/saved-cards
  Future<List<Map<String, dynamic>>> getSavedCards() async {
    final token = await TokenStorage.getAccess();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/billing/saved-cards'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded is List
          ? decoded.cast<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];
      _cachedSavedCards = list;
      return list;
    }
    throw Exception('Failed to fetch saved cards: ${response.body}');
  }

  /// Delete a saved card by Stripe PaymentMethod ID.
  /// Backend route: DELETE /billing/saved-cards/:pmId
  Future<void> deleteCard(String pmId) async {
    final token = await TokenStorage.getAccess();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .delete(
          Uri.parse('${AppConfig.baseUrl}/billing/saved-cards/$pmId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete card: ${response.body}');
    }
  }

  /// Set a card as the passenger's default payment method.
  /// Backend route: PATCH /billing/saved-cards/:pmId/default
  Future<void> setDefaultCard(String pmId) async {
    final token = await TokenStorage.getAccess();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .patch(
          Uri.parse('${AppConfig.baseUrl}/billing/saved-cards/$pmId/default'),
          headers: headers,
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to set default card: ${response.body}');
    }
  }

  /// Download the invoice/receipt PDF for a ride.
  /// Backend route: GET /billing/invoices/:rideId
  /// Returns the public download URL (caller opens it via url_launcher).
  Future<String> getReceiptDownloadUrl(String rideId) async {
    // The backend serves the PDF directly; we construct the URL so the
    // caller can open it with url_launcher (system browser handles download).
    return '${AppConfig.baseUrl}/billing/invoices/$rideId';
  }
}
