import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../services/mapbox/mapbox_service.dart';

/// Manages map operations: custom markers, dual-layer route, looping animation.
class MapManager {
  final mbx.MapboxMap mapboxMap;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;

  mbx.PointAnnotationManager? _pointManager;
  mbx.PolylineAnnotationManager? _baseRouteManager;
  mbx.PolylineAnnotationManager? _animRouteManager;

  List<mbx.Position> _routePositions = [];
  Timer? _animTimer;
  int _animStep = 0;
  bool _disposed = false;

  static const int _totalAnimSteps = 80;
  static const Duration _animInterval = Duration(milliseconds: 40);

  MapManager({
    required this.mapboxMap,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
  });

  // ── Public API ─────────────────────────────────────────────────────────

  /// One-shot setup: create managers, add markers, fetch route, start animation.
  Future<void> setup() async {
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _baseRouteManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _animRouteManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();

    await _addMarkers();
    await _fetchAndDrawRoute();
    await fitCameraToBounds();
    _startRouteAnimation();
  }

  /// Returns (pickupScreen, dropoffScreen) offsets for card positioning.
  Future<(Offset, Offset)?> getScreenPositions() async {
    try {
      final p = await mapboxMap.pixelForCoordinate(
        mbx.Point(coordinates: mbx.Position(pickupLon, pickupLat)),
      );
      final d = await mapboxMap.pixelForCoordinate(
        mbx.Point(coordinates: mbx.Position(dropoffLon, dropoffLat)),
      );
      return (Offset(p.x, p.y), Offset(d.x, d.y));
    } catch (e) {
      debugPrint('Error projecting screen positions: $e');
      return null;
    }
  }

  void dispose() {
    _disposed = true;
    _animTimer?.cancel();
  }

  // ── Markers ────────────────────────────────────────────────────────────

  Future<void> _addMarkers() async {
    if (_pointManager == null) return;

    // Pickup marker: bullseye (ring + inner dot)
    final pickupBytes = await _renderPickupMarker();
    if (pickupBytes != null) {
      await mapboxMap.style.addStyleImage(
        'pickup_marker',
        1.0,
        mbx.MbxImage(width: 48, height: 48, data: pickupBytes),
        false,
        [],
        [],
        null,
      );
      await _pointManager!.create(
        mbx.PointAnnotationOptions(
          geometry: mbx.Point(coordinates: mbx.Position(pickupLon, pickupLat)),
          iconImage: 'pickup_marker',
          iconSize: 1.0,
          iconAnchor: mbx.IconAnchor.CENTER,
        ),
      );
    }

    // Drop-off marker: teardrop pin
    final dropoffBytes = await _renderDropoffMarker();
    if (dropoffBytes != null) {
      await mapboxMap.style.addStyleImage(
        'dropoff_marker',
        1.0,
        mbx.MbxImage(width: 48, height: 64, data: dropoffBytes),
        false,
        [],
        [],
        null,
      );
      await _pointManager!.create(
        mbx.PointAnnotationOptions(
          geometry: mbx.Point(
            coordinates: mbx.Position(dropoffLon, dropoffLat),
          ),
          iconImage: 'dropoff_marker',
          iconSize: 1.0,
          iconAnchor: mbx.IconAnchor.BOTTOM,
        ),
      );
    }
  }

  /// Renders a 48x48 bullseye: outer ring + solid inner dot.
  Future<Uint8List?> _renderPickupMarker() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    // Outer ring
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = AppColors.primaryPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Inner filled dot
    canvas.drawCircle(center, 8, Paint()..color = AppColors.primaryPurple);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return bytes?.buffer.asUint8List();
  }

  /// Renders a 48x64 teardrop pin with white inner dot.
  Future<Uint8List?> _renderDropoffMarker() async {
    const w = 48.0;
    const h = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = AppColors.primaryPurple;

    // Teardrop path: circle at top + triangular tail pointing down
    final path = Path();
    const cx = w / 2;
    const cy = 20.0;
    const r = 16.0;

    // Upper circle
    path.addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r));

    // Triangular tail from circle bottom to pin tip
    path.moveTo(cx - r * 0.7, cy + r * 0.7);
    path.lineTo(cx, h - 4);
    path.lineTo(cx + r * 0.7, cy + r * 0.7);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black, 4.0, false);
    canvas.drawPath(path, paint);

    // White inner dot
    canvas.drawCircle(const Offset(cx, cy), 6, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return bytes?.buffer.asUint8List();
  }

  // ── Route ──────────────────────────────────────────────────────────────

  Future<void> _fetchAndDrawRoute() async {
    final routeGeometry = await MapboxService.getRouteGeometry(
      pickupLat,
      pickupLon,
      dropoffLat,
      dropoffLon,
    );

    // Convert flattened [lon, lat, lon, lat, ...] to Position list
    final positions = <mbx.Position>[];
    for (int i = 0; i < routeGeometry.length; i += 2) {
      positions.add(mbx.Position(routeGeometry[i], routeGeometry[i + 1]));
    }

    // Ensure route starts EXACTLY at pickup and ends EXACTLY at dropoff
    final pickupPos = mbx.Position(pickupLon, pickupLat);
    final dropoffPos = mbx.Position(dropoffLon, dropoffLat);

    if (positions.isEmpty) {
      positions.addAll([pickupPos, dropoffPos]);
    } else {
      // Replace first/last with exact marker coords to eliminate gaps
      positions[0] = pickupPos;
      positions[positions.length - 1] = dropoffPos;
    }

    _routePositions = positions;

    // Draw base (context) layer — full route, low opacity
    if (_baseRouteManager != null && positions.length >= 2) {
      await _baseRouteManager!.create(
        mbx.PolylineAnnotationOptions(
          geometry: mbx.LineString(coordinates: positions),
          lineColor: AppColors.primaryPurple.value,
          lineWidth: 5.0,
          lineOpacity: 0.25,
        ),
      );
    }
  }

  // ── Looping animation ──────────────────────────────────────────────────

  void _startRouteAnimation() {
    if (_routePositions.length < 2) return;
    _animStep = 0;

    _animTimer = Timer.periodic(_animInterval, (_) {
      if (_disposed) {
        _animTimer?.cancel();
        return;
      }
      _advanceAnimation();
    });
  }

  Future<void> _advanceAnimation() async {
    if (_animRouteManager == null || _routePositions.length < 2) return;

    _animStep++;
    if (_animStep > _totalAnimSteps) _animStep = 1; // loop

    final endIndex = (_routePositions.length * _animStep / _totalAnimSteps)
        .ceil()
        .clamp(2, _routePositions.length);

    try {
      await _animRouteManager!.deleteAll();
      await _animRouteManager!.create(
        mbx.PolylineAnnotationOptions(
          geometry: mbx.LineString(
            coordinates: _routePositions.sublist(0, endIndex),
          ),
          lineColor: AppColors.primaryPurple.value,
          lineWidth: 5.0,
          lineOpacity: 1.0,
        ),
      );
    } catch (e) {
      // Swallow — map may not be ready or widget disposed
    }
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Future<void> fitCameraToBounds() async {
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

      final camera = await mapboxMap.cameraForCoordinateBounds(
        bounds,
        mbx.MbxEdgeInsets(top: 140, left: 60, bottom: 320, right: 60),
        0,
        0,
        null,
        null,
      );

      await mapboxMap.flyTo(camera, mbx.MapAnimationOptions(duration: 800));
    } catch (e) {
      debugPrint('Error fitting camera to bounds: $e');
    }
  }
}
