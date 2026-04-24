import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../mapbox/mapbox_place.dart';
import '../mapbox/mapbox_service.dart';

class GpsService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }

  /// Get current position and reverse geocode to address
  static Future<MapboxPlace?> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      return await MapboxService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('GPS with address error: $e');
      return null;
    }
  }
}
