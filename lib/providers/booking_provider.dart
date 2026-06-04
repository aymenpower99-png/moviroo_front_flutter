import 'package:flutter/foundation.dart';
import '../services/ride_api/booking_api_service.dart';
import '../pages/tabs [passenger]/trajet/trajet_models.dart';
import '../services/driver_profile_cache.dart';

class BookingProvider with ChangeNotifier {
  final BookingApiService _api = BookingApiService();

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false; // Track if initial load happened
  DateTime? _lastRefresh; // Track last refresh time

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded; // NEW
  String? get error => _error;

  /// Load rides - skip API if already loaded (unless force=true)
  Future<void> loadRides({bool force = false}) async {
    // Return early if already loaded and not forcing refresh
    if (_hasLoaded && !force) {
      debugPrint('📦 [BookingProvider] Using cached rides');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📦 [BookingProvider] Fetching rides from API');
      final raw = await _api.getMyRides();
      _rides = raw.map(RideModel.fromJson).toList();

      // Populate driver cache so avatars are instant on every screen
      for (final ride in raw) {
        DriverProfileCache.instance.preloadFromRideJson(ride);
      }

      _hasLoaded = true;
      _lastRefresh = DateTime.now();
      _isLoading = false;
      notifyListeners();
      debugPrint('📦 [BookingProvider] Loaded ${_rides.length} rides');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('📦 [BookingProvider] Failed to load rides: $e');
    }
  }

  /// Force refresh from API
  Future<void> refreshRides() async {
    await loadRides(force: true);
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
