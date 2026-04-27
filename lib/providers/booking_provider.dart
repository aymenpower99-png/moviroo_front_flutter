import 'package:flutter/foundation.dart';
import '../services/ride_api/booking_api_service.dart';
import '../pages/tabs [passenger]/trajet/trajet_models.dart';

class BookingProvider with ChangeNotifier {
  final BookingApiService _api = BookingApiService();
  
  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _error;

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all rides from backend
  Future<void> loadRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _api.getMyRides();
      _rides = raw.map(RideModel.fromJson).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh rides (called after booking status changes)
  Future<void> refreshRides() async {
    await loadRides();
  }

  /// Notify that a booking was cancelled
  Future<void> onBookingCancelled() async {
    await refreshRides();
  }

  /// Notify that a booking was confirmed
  Future<void> onBookingConfirmed() async {
    await refreshRides();
  }

  /// Notify that payment was completed
  Future<void> onPaymentCompleted() async {
    await refreshRides();
  }

  /// Notify that payment failed
  Future<void> onPaymentFailed() async {
    await refreshRides();
  }
}
