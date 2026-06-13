import 'dart:convert';
import './auth/auth_http.dart';

/// Service for submitting passenger ratings for completed rides.
class TripRatingService {
  /// Submit passenger rating for the driver of a completed ride.
  /// 
  /// [rideId] - the ride ID
  /// [rating] - 1-5 stars
  static Future<void> submitRating(String rideId, int rating) async {
    final response = await AuthHTTP.authenticatedPost(
      '/trips/$rideId/rate',
      {'passenger_rating': rating},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Failed to submit rating';
      throw Exception(message);
    }
  }
}
