import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../services/mapbox/mapbox_service.dart';

/// Manages all map-related operations for the ride booking page.
class MapManager {
  final mbx.MapboxMap? mapboxMap;
  final mbx.PointAnnotationManager? pointAnnotationManager;
  final mbx.PolylineAnnotationManager? polylineAnnotationManager;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final VoidCallback onScreenPositionUpdate;

  MapManager({
    required this.mapboxMap,
    required this.pointAnnotationManager,
    required this.polylineAnnotationManager,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.onScreenPositionUpdate,
  });

  /// Projects pickup/dropoff geographic coords to screen pixels so that
  /// the floating location cards stay anchored above their markers while
  /// the user pans or zooms the map.
  Future<void> updateScreenPositions(
    void Function(Offset? pickupScreen, Offset? dropoffScreen)
    onPositionsUpdated,
  ) async {
    final map = mapboxMap;
    if (map == null) return;

    try {
      final pickupCoord = await map.pixelForCoordinate(
        mbx.Point(coordinates: mbx.Position(pickupLon, pickupLat)),
      );
      final dropoffCoord = await map.pixelForCoordinate(
        mbx.Point(coordinates: mbx.Position(dropoffLon, dropoffLat)),
      );

      onPositionsUpdated(
        Offset(pickupCoord.x, pickupCoord.y),
        Offset(dropoffCoord.x, dropoffCoord.y),
      );
      onScreenPositionUpdate();
    } catch (e) {
      debugPrint('Error projecting screen positions: $e');
    }
  }

  /// Fit the map camera to show both pickup and dropoff markers with
  /// comfortable padding on all sides.
  Future<void> fitCameraToBounds() async {
    if (mapboxMap == null) return;

    try {
      final southLat = min(pickupLat, dropoffLat);
      final northLat = max(pickupLat, dropoffLat);
      final westLon = min(pickupLon, dropoffLon);
      final eastLon = max(pickupLon, dropoffLon);

      final bounds = mbx.CoordinateBounds(
        southwest: mbx.Point(coordinates: mbx.Position(westLon, southLat)),
        northeast: mbx.Point(coordinates: mbx.Position(eastLon, northLat)),
        infiniteBounds: false,
      );

      final camera = await mapboxMap!.cameraForCoordinateBounds(
        bounds,
        mbx.MbxEdgeInsets(top: 140, left: 60, bottom: 320, right: 60),
        0, // bearing
        0, // pitch
        null, // maxZoom
        null, // offset
      );

      await mapboxMap!.flyTo(camera, mbx.MapAnimationOptions(duration: 800));

      // Update card positions after camera settles
      await Future.delayed(const Duration(milliseconds: 900));
      await updateScreenPositions((_, __) {});
    } catch (e) {
      debugPrint('Error fitting camera to bounds: $e');
    }
  }

  /// Adds pickup and dropoff markers to the map and draws the route polyline.
  Future<void> addMarkersAndPolyline() async {
    if (mapboxMap == null) return;

    try {
      // Add pickup marker
      final pickupOptions = mbx.PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(pickupLon, pickupLat)),
        iconSize: 0.3,
        textField: '',
        iconImage: 'default_marker',
      );
      await pointAnnotationManager?.create(pickupOptions);

      // Add dropoff marker
      final dropoffOptions = mbx.PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(dropoffLon, dropoffLat)),
        iconSize: 0.3,
        textField: '',
        iconImage: 'default_marker',
      );
      await pointAnnotationManager?.create(dropoffOptions);

      // Fetch real route geometry from Mapbox Directions API
      final routeGeometry = await MapboxService.getRouteGeometry(
        pickupLat,
        pickupLon,
        dropoffLat,
        dropoffLon,
      );

      // Convert flattened array to Position list for LineString
      final positions = <mbx.Position>[];
      for (int i = 0; i < routeGeometry.length; i += 2) {
        positions.add(mbx.Position(routeGeometry[i], routeGeometry[i + 1]));
      }

      // Ensure route starts exactly at pickup and ends exactly at dropoff
      final pickupPos = mbx.Position(pickupLon, pickupLat);
      final dropoffPos = mbx.Position(dropoffLon, dropoffLat);

      if (positions.isNotEmpty) {
        final first = positions.first;
        if (first.lng != pickupPos.lng || first.lat != pickupPos.lat) {
          positions.insert(0, pickupPos);
        }
        final last = positions.last;
        if (last.lng != dropoffPos.lng || last.lat != dropoffPos.lat) {
          positions.add(dropoffPos);
        }
      } else {
        positions.addAll([pickupPos, dropoffPos]);
      }

      // Fit camera to show both markers with padding
      await fitCameraToBounds();

      // Animate the route polyline (progressive drawing over 1.5s)
      await animatePolyline(positions);
    } catch (e) {
      debugPrint('Error adding markers and polyline: $e');
    }
  }

  /// Progressively draws the polyline from pickup → dropoff over 1.5 seconds,
  /// using a simple loop with 30 steps (~50ms each = 1500ms total).
  Future<void> animatePolyline(List<mbx.Position> positions) async {
    if (polylineAnnotationManager == null || positions.length < 2) return;

    const totalSteps = 30;
    const stepDuration = Duration(milliseconds: 50);

    for (int step = 1; step <= totalSteps; step++) {
      final endIndex = (positions.length * step / totalSteps).ceil().clamp(
        2,
        positions.length,
      );

      try {
        await polylineAnnotationManager?.deleteAll();
        await polylineAnnotationManager?.create(
          mbx.PolylineAnnotationOptions(
            geometry: mbx.LineString(
              coordinates: positions.sublist(0, endIndex),
            ),
            lineColor: AppColors.primaryPurple.value,
            lineWidth: 5.0,
            lineOpacity: 1.0,
          ),
        );
      } catch (e) {
        debugPrint('Error animating polyline step $step: $e');
      }

      if (step < totalSteps) {
        await Future.delayed(stepDuration);
      }
    }
  }
}
