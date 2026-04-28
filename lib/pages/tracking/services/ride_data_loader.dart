import '../../../services/ride_api/booking_api_service.dart';

/// Service for loading ride details from backend.
class RideDataLoader {
  double backendPickupLat = 0;
  double backendPickupLon = 0;
  double backendDropoffLat = 0;
  double backendDropoffLon = 0;
  String backendPickupAddress = '';
  String backendDropoffAddress = '';
  String backendDriverName = '';
  String backendVehicleName = '';
  String backendVehicleColor = '';
  String backendPlateNumber = '';

  /// Load ride details from backend API.
  Future<void> loadRideDetails(String rideId) async {
    try {
      final bookingApiService = BookingApiService();
      final rideDetails = await bookingApiService.getRideDetails(rideId);

      if (rideDetails != null) {
        backendPickupLat = (rideDetails['pickupLat'] as num?)?.toDouble() ?? 0;
        backendPickupLon = (rideDetails['pickupLon'] as num?)?.toDouble() ?? 0;
        backendDropoffLat =
            (rideDetails['dropoffLat'] as num?)?.toDouble() ?? 0;
        backendDropoffLon =
            (rideDetails['dropoffLon'] as num?)?.toDouble() ?? 0;
        backendPickupAddress = rideDetails['pickupAddress'] as String? ?? '';
        backendDropoffAddress = rideDetails['dropoffAddress'] as String? ?? '';
        backendDriverName = rideDetails['driverName'] as String? ?? '';
        backendVehicleName = rideDetails['vehicleName'] as String? ?? '';
        backendVehicleColor = rideDetails['vehicleColor'] as String? ?? '';
        backendPlateNumber = rideDetails['plateNumber'] as String? ?? '';
      }
    } catch (e) {
      // Errors are tolerated - caller handles null/empty values
    }
  }
}
