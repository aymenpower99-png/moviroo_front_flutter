import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'utils.dart';
import 'widgets.dart';

/// Full-screen map view for the [RideBookingPage].
///
/// Renders the Mapbox map, the back button, and the two anchored location
/// cards (pickup + drop-off) that float above their respective markers on
/// the map.
///
/// IMPORTANT: this widget returns a list of [Stack] children, so it must be
/// spread into a parent [Stack].
class RideBookingMapView extends StatelessWidget {
  // Map setup
  final bool isDark;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final void Function(mbx.MapboxMap) onMapCreated;
  final void Function(mbx.StyleLoadedEventData) onStyleLoaded;
  final void Function(mbx.CameraChangedEventData) onCameraChanged;

  // Anchored cards data
  final Offset? pickupScreen;
  final Offset? dropoffScreen;
  final double screenWidth;
  final bool isLoadingAddresses;
  final String pickupAddress;
  final String dropoffAddress;
  final String pickupCity;
  final String pickupCountry;
  final String dropoffCity;
  final String dropoffCountry;

  const RideBookingMapView({
    super.key,
    required this.isDark,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.onMapCreated,
    required this.onStyleLoaded,
    required this.onCameraChanged,
    required this.pickupScreen,
    required this.dropoffScreen,
    required this.screenWidth,
    required this.isLoadingAddresses,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupCity,
    required this.pickupCountry,
    required this.dropoffCity,
    required this.dropoffCountry,
  });

  @override
  Widget build(BuildContext context) {
    // This widget returns a Stack so it can be embedded directly in the
    // parent's body Stack via a Positioned.fill — but because we need to
    // also place the back button and anchored cards as siblings of the
    // map (not inside the map), we use a Stack here that fills the parent.
    return Stack(
      children: [
        // ── Mapbox map (full screen) ──────────────────────────────────────
        Positioned.fill(
          child: mbx.MapWidget(
            styleUri: isDark
                ? mbx.MapboxStyles.DARK
                : mbx.MapboxStyles.MAPBOX_STREETS,
            onMapCreated: onMapCreated,
            onStyleLoadedListener: onStyleLoaded,
            onCameraChangeListener: onCameraChanged,
            cameraOptions: mbx.CameraOptions(
              center: mbx.Point(
                coordinates: mbx.Position(
                  (pickupLon + dropoffLon) / 2,
                  (pickupLat + dropoffLat) / 2,
                ),
              ),
              zoom: 14.0,
              bearing: 0.0,
              pitch: 0.0,
            ),
          ),
        ),

        // ── Back button ───────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: const BackButtonWidget(),
        ),

        // ── Pickup location card ──────────────────────────────────────────
        if (pickupScreen != null)
          AnchoredLocationCard(
            markerScreen: pickupScreen!,
            screenWidth: screenWidth,
            name: isLoadingAddresses && pickupAddress.isEmpty
                ? 'Loading...'
                : pickupAddress,
            subtitle: cityCountry(pickupCity, pickupCountry),
            isPickup: true,
          ),

        // ── Drop-off location card ────────────────────────────────────────
        if (dropoffScreen != null)
          AnchoredLocationCard(
            markerScreen: dropoffScreen!,
            screenWidth: screenWidth,
            name: isLoadingAddresses && dropoffAddress.isEmpty
                ? 'Loading...'
                : dropoffAddress,
            subtitle: cityCountry(dropoffCity, dropoffCountry),
            isPickup: false,
          ),
      ],
    );
  }
}
