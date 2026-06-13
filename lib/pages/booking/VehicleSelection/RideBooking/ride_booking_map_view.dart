import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
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

  // Card estimated height: body(46) + triangle(7) + gap(4) = 57dp
  static const double _cardH = 57.0;
  static const double _minCardGap = 20.0;

  /// Adjust screen offsets so the two cards never visually collide.
  /// The card with a lower Y (higher on screen) keeps its position;
  /// the other is pushed down enough to maintain [_minCardGap].
  (Offset, Offset) _separatedPositions(Offset a, Offset b) {
    final aTop = a.dy - _cardH;
    final bTop = b.dy - _cardH;
    final aBottom = a.dy;
    final bBottom = b.dy;

    // Determine which card is higher (smaller top y)
    if (aTop < bTop) {
      // a is above b — check if b's card overlaps a's card
      final overlap = aBottom + _minCardGap - bTop;
      if (overlap > 0) {
        return (a, Offset(b.dx, b.dy + overlap));
      }
    } else {
      // b is above a — check if a's card overlaps b's card
      final overlap = bBottom + _minCardGap - aTop;
      if (overlap > 0) {
        return (Offset(a.dx, a.dy + overlap), b);
      }
    }
    return (a, b);
  }

  @override
  Widget build(BuildContext context) {
    // Separate cards if they are too close vertically.
    // The drop-off marker is anchored at BOTTOM on an 80×80 canvas.
    // Its visual center is 40 px above the anchor point. Lifting the card
    // by 40 px positions the card at the marker center, exactly like the
    // pickup card (which is anchored at CENTER). The marker extends below
    // the card, leaving no visible gap.
    final Offset? adjustedPickup;
    final Offset? adjustedDropoff;
    if (pickupScreen != null && dropoffScreen != null) {
      final dropoff = dropoffScreen!;
final dropoffLifted = Offset(dropoff.dx, dropoff.dy - 15);
      final (p, d) = _separatedPositions(pickupScreen!, dropoffLifted);
      adjustedPickup = p;
      adjustedDropoff = d;
    } else {
      adjustedPickup = pickupScreen;
      adjustedDropoff = dropoffScreen;
    }

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
        if (adjustedPickup != null)
          AnchoredLocationCard(
            markerScreen: adjustedPickup,
            screenWidth: screenWidth,
            name: isLoadingAddresses && pickupAddress.isEmpty
                ? 'Loading...'
                : pickupAddress,
            subtitle: pickupCity,
            country: pickupCountry,
            isPickup: true,
          ),

        // ── Drop-off location card ────────────────────────────────────────
        if (adjustedDropoff != null)
          AnchoredLocationCard(
            markerScreen: adjustedDropoff,
            screenWidth: screenWidth,
            name: isLoadingAddresses && dropoffAddress.isEmpty
                ? 'Loading...'
                : dropoffAddress,
            subtitle: dropoffCity,
            country: dropoffCountry,
            isPickup: false,
          ),
      ],
    );
  }
}
