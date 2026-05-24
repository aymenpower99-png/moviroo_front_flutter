import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../geocoding/geocoding_service.dart';

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

  /// Open system location settings (for when services are disabled)
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings (for when permission is denied forever)
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Get a fresh, accurate position.
  /// Rejects cached/stale positions (older than 30 seconds).
  /// Uses position stream with timeout to force GPS hardware to wake up.
  static Future<Position?> getAccuratePosition() async {
    try {
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // First attempt: immediate reading
      Position? best = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Reject if stale (> 30 seconds old) or too inaccurate (> 200m)
      final now = DateTime.now();
      final posAge = now.difference(best.timestamp ?? now);
      if (posAge.inSeconds <= 30 && best.accuracy <= 200) {
        debugPrint('[GPS] Immediate fix OK: accuracy=${best.accuracy}m, age=${posAge.inSeconds}s');
        return best;
      }

      debugPrint('[GPS] Immediate fix rejected (accuracy=${best.accuracy}m, age=${posAge.inSeconds}s). Waiting for better fix...');

      // Second attempt: listen to position stream for up to 8 seconds
      // This forces the GPS hardware to actually acquire satellites
      Position? streamBest;
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      final completer = Completer<Position?>();
      StreamSubscription<Position>? sub;

      sub = stream.listen(
        (pos) {
          final age = now.difference(pos.timestamp ?? now);
          debugPrint('[GPS] Stream update: accuracy=${pos.accuracy}m, age=${age.inSeconds}s');
          if (streamBest == null || pos.accuracy < streamBest!.accuracy) {
            streamBest = pos;
          }
          if (age.inSeconds <= 30 && pos.accuracy <= 100) {
            completer.complete(pos);
            sub?.cancel();
          }
        },
        onError: (e) {
          debugPrint('[GPS] Stream error: $e');
          completer.complete(null);
        },
      );

      // Timeout after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          completer.complete(streamBest ?? best);
          sub?.cancel();
        }
      });

      final result = await completer.future;
      await sub?.cancel();
      return result;
    } catch (e) {
      debugPrint('[GPS] Error getting accurate position: $e');
      return null;
    }
  }

  /// Show a permission dialog and guide the user to enable location.
  /// Returns true if permission was granted after the dialog flow.
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are turned off on your device. Please enable them in Settings to use your current location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (goToSettings == true) {
        await openLocationSettings();
      }
      return false;
    }

    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      final request = await requestPermission();
      if (request == LocationPermission.denied) {
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'We need access to your location to find your current address and show nearby places. Please grant permission in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (retry == true) {
          await openAppSettings();
        }
        return false;
      }
      return request == LocationPermission.whileInUse ||
          request == LocationPermission.always;
    }

    if (permission == LocationPermission.deniedForever) {
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text(
            'You have permanently denied location permission. Please enable it in app settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (goToSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current position and create a GeocodingPlace with real address.
  /// Shows a warning dialog if the location seems inaccurate.
  static Future<GeocodingPlace?> getCurrentLocationWithAddress(
    BuildContext context, {
    String? language,
  }) async {
    try {
      final position = await getAccuratePosition();
      if (position == null) return null;

      // Validate accuracy again
      final age = DateTime.now().difference(position.timestamp ?? DateTime.now());
      if (age.inSeconds > 60 || position.accuracy > 200) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location May Be Inaccurate'),
            content: Text(
              'We detected your location with an accuracy of ${position.accuracy.toStringAsFixed(0)} meters. '
              'If this does not look correct, please select your location manually on the map.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Use Anyway'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Select on Map'),
              ),
            ],
          ),
        );
        if (proceed == true) return null; // User wants to use map picker instead
      }

      // Reverse geocode to get a human-readable address
      final place = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
        language: language,
      );

      if (place != null) {
        return place.copyWith(source: 'gps');
      }

      // Fallback if reverse geocoding fails
      return GeocodingPlace(
        id: 'gps-${DateTime.now().millisecondsSinceEpoch}',
        placeName: 'Current Location',
        address: null,
        latitude: position.latitude,
        longitude: position.longitude,
        source: 'gps',
      );
    } catch (e) {
      debugPrint('GPS with address error: $e');
      return null;
    }
  }
}
