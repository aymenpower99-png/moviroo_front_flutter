import 'package:flutter/foundation.dart';
import '../../../services/ride_api/booking_api_service.dart';
import '../../../services/driver_profile_cache.dart';

/// Service for loading ride details from backend.
class RideDataLoader {
  // Static ride data
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
  String backendDriverPhotoUrl = '';
  String backendDriverPhoneNumber = '';
  String backendVehicleMake = '';
  String backendVehicleModel = '';
  double backendDriverRating = 0.0;

  // Driver location and progress/ETA from REST (computed by RoutingService)
  double? backendDriverLat;
  double? backendDriverLon;
  DateTime? backendDriverLastUpdatedAt;
  double? backendProgress;
  int? backendEtaMins;
  int? backendRemainingDistanceMeters;

  /// Load ride details from backend API.
  Future<void> loadRideDetails(String rideId) async {
    try {
      final bookingApiService = BookingApiService();
      final rideDetails = await bookingApiService.getRideDetails(rideId);

      if (rideDetails != null) {
        debugPrint('📡 REST Response keys: ${rideDetails.keys.toList()}');
        debugPrint('📡 REST Response: $rideDetails');

        // Extract static ride data
        backendPickupLat = (rideDetails['pickupLat'] as num?)?.toDouble() ?? 0;
        backendPickupLon = (rideDetails['pickupLon'] as num?)?.toDouble() ?? 0;
        backendDropoffLat =
            (rideDetails['dropoffLat'] as num?)?.toDouble() ?? 0;
        backendDropoffLon =
            (rideDetails['dropoffLon'] as num?)?.toDouble() ?? 0;
        backendPickupAddress = rideDetails['pickupAddress'] as String? ?? '';
        backendDropoffAddress = rideDetails['dropoffAddress'] as String? ?? '';
        backendDriverName = rideDetails['driverName'] as String? ?? '';

        // Vehicle name - try multiple locations for maker + model
        backendVehicleName = rideDetails['vehicleName'] as String? ?? '';
        if (backendVehicleName.isEmpty) {
          // Try nested vehicle object
          final vehicle = rideDetails['vehicle'] as Map<String, dynamic>?;
          if (vehicle != null) {
            final make =
                vehicle['make'] as String? ?? vehicle['brand'] as String? ?? '';
            final model = vehicle['model'] as String? ?? '';
            if (make.isNotEmpty && model.isNotEmpty) {
              backendVehicleName = '$make $model';
            } else if (make.isNotEmpty) {
              backendVehicleName = make;
            } else if (model.isNotEmpty) {
              backendVehicleName = model;
            }
          }
        }
        if (backendVehicleName.isEmpty) {
          // Try vehicleClass name
          final vehicleClass =
              rideDetails['vehicleClass'] as Map<String, dynamic>?;
          if (vehicleClass != null) {
            backendVehicleName = vehicleClass['name'] as String? ?? '';
          }
        }

        // Extract vehicle make and model separately for chat page
        backendVehicleMake =
            (rideDetails['vehicleMake'] as String?) ??
            (rideDetails['vehicle_make'] as String?) ??
            '';
        backendVehicleModel =
            (rideDetails['vehicleModel'] as String?) ??
            (rideDetails['vehicle_model'] as String?) ??
            '';

        // Fallback: try to extract from nested vehicle object
        if (backendVehicleMake.isEmpty || backendVehicleModel.isEmpty) {
          final vehicle = rideDetails['vehicle'] as Map<String, dynamic>?;
          if (vehicle != null) {
            if (backendVehicleMake.isEmpty) {
              backendVehicleMake =
                  vehicle['make'] as String? ??
                  vehicle['brand'] as String? ??
                  '';
            }
            if (backendVehicleModel.isEmpty) {
              backendVehicleModel = vehicle['model'] as String? ?? '';
            }
          }
        }

        backendVehicleColor = rideDetails['vehicleColor'] as String? ?? '';
        backendPlateNumber = rideDetails['plateNumber'] as String? ?? '';
        backendDriverPhoneNumber =
            (rideDetails['driverPhoneNumber'] as String?) ??
            (rideDetails['driver_phone_number'] as String?) ??
            (rideDetails['driverPhone'] as String?) ??
            (rideDetails['driver_phone'] as String?) ??
            '';
        debugPrint('📱 Driver phone from REST: $backendDriverPhoneNumber');

        // Driver average rating - confirmed from logs: driverRating at root level
        // Handle both String and num types from backend
        double parseRating(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        backendDriverRating = parseRating(rideDetails['driverRating']);
        if (backendDriverRating == 0.0) {
          backendDriverRating = parseRating(rideDetails['rating_average']);
        }
        if (backendDriverRating == 0.0) {
          backendDriverRating = parseRating(rideDetails['ratingAverage']);
        }
        if (backendDriverRating == 0.0) {
          backendDriverRating = parseRating(rideDetails['averageRating']);
        }
        if (backendDriverRating == 0.0) {
          backendDriverRating = parseRating(rideDetails['rating']);
        }

        debugPrint('⭐ Driver rating from REST: $backendDriverRating');

        // Driver photo — prefer driverLogoUrl (from Driver.logoUrl), fallback to other keys if backend differs
        backendDriverPhotoUrl =
            (rideDetails['driverLogoUrl'] as String?) ??
            (rideDetails['driverPhotoUrl'] as String?) ??
            (rideDetails['driver_logo_url'] as String?) ??
            (rideDetails['driverLogoUrl'] as String?) ??
            (rideDetails['driverPhoto'] as String?) ??
            '';

        // Cache driver profile so avatars are instant on every screen
        final driverMap = rideDetails['driver'] as Map<String, dynamic>?;
        if (driverMap != null) {
          final driverId =
              driverMap['id'] as String? ?? driverMap['userId'] as String?;
          if (driverId != null && driverId.isNotEmpty) {
            DriverProfileCache.instance.set(driverId, {
              ...driverMap,
              'logoUrl': backendDriverPhotoUrl,
            });
          }
          // Fallback: try to get phone from nested driver object
          if (backendDriverPhoneNumber.isEmpty) {
            backendDriverPhoneNumber =
                (driverMap['phoneNumber'] as String?) ??
                (driverMap['phone'] as String?) ??
                (driverMap['phone_number'] as String?) ??
                '';
          }
        }

        // If still no phone, try to get from driver profile cache using driver ID
        if (backendDriverPhoneNumber.isEmpty && driverMap != null) {
          final driverId =
              driverMap['id'] as String? ?? driverMap['userId'] as String?;
          if (driverId != null && driverId.isNotEmpty) {
            final cachedProfile = DriverProfileCache.instance.get(driverId);
            if (cachedProfile != null) {
              backendDriverPhoneNumber =
                  (cachedProfile['phoneNumber'] as String?) ??
                  (cachedProfile['phone'] as String?) ??
                  (cachedProfile['phone_number'] as String?) ??
                  '';
              debugPrint(
                '📱 Driver phone from cache: $backendDriverPhoneNumber',
              );
            }
          }
        }

        // Extract driver location and progress/ETA from REST (computed by RoutingService)
        final driverLoc =
            rideDetails['driver_location'] as Map<String, dynamic>?;
        debugPrint('📍 Driver location from REST: $driverLoc');
        if (driverLoc != null) {
          backendDriverLat = (driverLoc['latitude'] as num?)?.toDouble();
          backendDriverLon = (driverLoc['longitude'] as num?)?.toDouble();
          final lastUpdatedAt = driverLoc['last_updated_at'] as String?;
          if (lastUpdatedAt != null) {
            backendDriverLastUpdatedAt = DateTime.parse(lastUpdatedAt);
          }
        }

        backendProgress = (rideDetails['progress'] as num?)?.toDouble();
        backendEtaMins = (rideDetails['etaMins'] as num?)?.toInt();
        backendRemainingDistanceMeters =
            (rideDetails['remainingDistanceMeters'] as num?)?.toInt();

        debugPrint(
          '📊 Progress from REST: $backendProgress, ETA: $backendEtaMins mins',
        );
      } else {
        debugPrint('⚠️ REST response is null');
      }
    } catch (e) {
      debugPrint('❌ REST load error: $e');
      // Errors are tolerated - caller handles null/empty values
    }
  }
}
