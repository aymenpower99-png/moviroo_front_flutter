import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../services/mapbox/mapbox_service.dart';
import 'map_painters.dart';

/// Manages map operations: custom markers, dual-layer route, looping animation.
class MapManager {
  final mbx.MapboxMap mapboxMap;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final BuildContext context; // For theme detection

  mbx.PointAnnotationManager? _pointManager;
  mbx.PolylineAnnotationManager? _baseRouteManager;
  mbx.PolylineAnnotationManager? _animRouteManager;

  List<mbx.Position> _routePositions = [];
  Timer? _animTimer;
  int _animStep = 0;
  bool _disposed = false;
  String? _currentAnimPolylineId;

  static const int _totalAnimSteps = 80;
  static const Duration _animInterval = Duration(milliseconds: 40);

  MapManager({
    required this.mapboxMap,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.context,
  });

  // ── Public API ─────────────────────────────────────────────────────────

  /// One-shot setup: create managers, add markers, fetch route, start animation.
  Future<void> setup() async {
    debugPrint('[MapManager] setup started');

    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _baseRouteManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _animRouteManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();

    debugPrint('[MapManager] annotation managers created');

    await _addMarkers();
    debugPrint('[MapManager] markers added');

    await _fetchAndDrawRoute();
    debugPrint('[MapManager] route fetched and base layer drawn');

    await fitCameraToBounds();
    debugPrint('[MapManager] camera fitted');

    _startRouteAnimation();
    debugPrint('[MapManager] animation started');
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

  /// Pause the looping animation. Cancels and nullifies the timer.
  /// The animation can be resumed later via [resumeAnimation].
  void pauseAnimation() {
    if (_animTimer == null) {
      debugPrint('[MapManager] pauseAnimation: no active timer');
      return;
    }
    debugPrint('[MapManager] pauseAnimation: cancelling timer');
    _animTimer?.cancel();
    _animTimer = null;
  }

  /// Resume the looping animation if it was paused.
  /// Does nothing if disposed or already running.
  void resumeAnimation() {
    if (_disposed) {
      debugPrint('[MapManager] resumeAnimation: skipped (disposed)');
      return;
    }
    if (_animTimer != null) {
      debugPrint('[MapManager] resumeAnimation: skipped (already running)');
      return;
    }
    if (_routePositions.length < 2) {
      debugPrint('[MapManager] resumeAnimation: skipped (no route)');
      return;
    }
    debugPrint('[MapManager] resumeAnimation: restarting timer');
    _startRouteAnimation();
  }

  void dispose() {
    debugPrint('[MapManager] dispose called');
    _disposed = true;
    _animTimer?.cancel();
    _animTimer = null;
    debugPrint('[MapManager] dispose completed, timer cancelled and nullified');
  }

  // ── Markers ────────────────────────────────────────────────────────────

  Future<void> _addMarkers() async {
    if (_pointManager == null) return;

    debugPrint(
      '[MapManager] _addMarkers started - using driver app marker implementation',
    );

    // Pickup marker: using driver app's exact implementation
    await _pointManager!.create(
      mbx.PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(pickupLon, pickupLat)),
        image: await MapPainters.renderPickupBitmap(),
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.CENTER,
      ),
    );
    debugPrint('[MapManager] pickup marker added (driver app style)');

    // Drop-off marker: using driver app's exact implementation
    await _pointManager!.create(
      mbx.PointAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(dropoffLon, dropoffLat)),
        image: await MapPainters.renderDropoffBitmap(),
        iconSize: 1.0,
        iconAnchor: mbx.IconAnchor.BOTTOM,
      ),
    );
    debugPrint('[MapManager] dropoff marker added (driver app style)');
  }

  // ── Route ──────────────────────────────────────────────────────────────

  Future<void> _fetchAndDrawRoute() async {
    debugPrint('[MapManager] _fetchAndDrawRoute started');

    try {
      final routeGeometry = await MapboxService.getRouteGeometry(
        pickupLat,
        pickupLon,
        dropoffLat,
        dropoffLon,
      );

      debugPrint('[MapManager] routeGeometry length: ${routeGeometry.length}');

      // Convert flattened [lon, lat, lon, lat, ...] to Position list
      final positions = <mbx.Position>[];
      for (int i = 0; i < routeGeometry.length; i += 2) {
        positions.add(mbx.Position(routeGeometry[i], routeGeometry[i + 1]));
      }

      debugPrint(
        '[MapManager] converted to ${positions.length} Position objects',
      );

      // Ensure route starts EXACTLY at pickup and ends EXACTLY at dropoff
      final pickupPos = mbx.Position(pickupLon, pickupLat);
      final dropoffPos = mbx.Position(dropoffLon, dropoffLat);

      if (positions.isEmpty) {
        debugPrint('[MapManager] routeGeometry empty, drawing debug line');
        await _drawDebugLine(pickupPos, dropoffPos);
        return;
      } else {
        // Replace first/last with exact marker coords to eliminate gaps
        positions[0] = pickupPos;
        positions[positions.length - 1] = dropoffPos;
      }

      _routePositions = positions;
      debugPrint(
        '[MapManager] final routePositions: ${_routePositions.length}',
      );

      // Draw base (context) layer — full route, low opacity
      if (_baseRouteManager != null && positions.length >= 2) {
        debugPrint('[MapManager] creating base polyline');
        await _baseRouteManager!.create(
          mbx.PolylineAnnotationOptions(
            geometry: mbx.LineString(coordinates: positions),
            lineColor: AppColors.primaryPurple.toARGB32(),
            lineWidth: 5.0,
            lineOpacity: 0.25,
          ),
        );
        debugPrint('[MapManager] base polyline created');
      } else {
        debugPrint(
          '[MapManager] base polyline NOT created: manager=${_baseRouteManager != null}, positions=${positions.length}',
        );
        await _drawDebugLine(pickupPos, dropoffPos);
      }
    } catch (e) {
      debugPrint('[MapManager] route fetch error: $e');
      final pickupPos = mbx.Position(pickupLon, pickupLat);
      final dropoffPos = mbx.Position(dropoffLon, dropoffLat);
      await _drawDebugLine(pickupPos, dropoffPos);
    }
  }

  /// Draw debug line (red straight line) when route fails
  Future<void> _drawDebugLine(mbx.Position pickup, mbx.Position dropoff) async {
    if (_baseRouteManager == null) return;
    try {
      final debugPositions = [pickup, dropoff];
      await _baseRouteManager!.create(
        mbx.PolylineAnnotationOptions(
          geometry: mbx.LineString(coordinates: debugPositions),
          lineColor: Colors.red.toARGB32(),
          lineWidth: 3.0,
          lineOpacity: 0.8,
        ),
      );
      debugPrint('[MapManager] debug line drawn');
    } catch (e) {
      debugPrint('[MapManager] debug line draw failed: $e');
    }
  }

  // ── Looping animation ──────────────────────────────────────────────────

  void _startRouteAnimation() {
    debugPrint(
      '[MapManager] _startRouteAnimation: routePositions=${_routePositions.length}',
    );
    if (_routePositions.length < 2) {
      debugPrint('[MapManager] animation NOT started: insufficient positions');
      return;
    }
    if (_disposed) {
      debugPrint('[MapManager] animation NOT started: already disposed');
      return;
    }
    if (_animTimer != null) {
      debugPrint('[MapManager] animation NOT started: timer already exists');
      return;
    }
    _animStep = 0;

    _animTimer = Timer.periodic(_animInterval, (_) {
      if (_disposed) {
        debugPrint('[MapManager] animation timer cancelled (disposed)');
        return;
      }
      _advanceAnimation();
    });
    debugPrint('[MapManager] animation timer started');
  }

  Future<void> _advanceAnimation() async {
    if (_disposed) {
      debugPrint('[MapManager] _advanceAnimation skipped: disposed');
      return;
    }
    if (_animRouteManager == null || _routePositions.length < 2) {
      debugPrint(
        '[MapManager] _advanceAnimation skipped: manager=${_animRouteManager != null}, positions=${_routePositions.length}',
      );
      return;
    }

    _animStep++;
    if (_animStep > _totalAnimSteps) _animStep = 1;

    // Calculate progress (0.0 to 1.0)
    final progress = _animStep / _totalAnimSteps;

    // Calculate route segment
    final endIndex = (_routePositions.length * progress).ceil().clamp(
      2,
      _routePositions.length,
    );

    try {
      // Create polyline on first frame, then update geometry on subsequent frames
      if (_currentAnimPolylineId == null) {
        final annotation = await _animRouteManager!.create(
          mbx.PolylineAnnotationOptions(
            geometry: mbx.LineString(
              coordinates: _routePositions.sublist(0, endIndex),
            ),
            lineColor: AppColors.primaryPurple.toARGB32(),
            lineWidth: 5.0,
            lineOpacity: 1.0,
          ),
        );
        _currentAnimPolylineId = annotation.id;
      } else {
        // Try to update existing annotation
        try {
          await _animRouteManager!.update(
            mbx.PolylineAnnotation(
              id: _currentAnimPolylineId!,
              geometry: mbx.LineString(
                coordinates: _routePositions.sublist(0, endIndex),
              ),
              lineColor: AppColors.primaryPurple.toARGB32(),
              lineWidth: 5.0,
              lineOpacity: 1.0,
            ),
          );
        } catch (e) {
          // If update fails, fall back to delete/create
          debugPrint(
            '[MapManager] update failed, falling back to delete/create: $e',
          );
          await _animRouteManager!.deleteAll();
          final annotation = await _animRouteManager!.create(
            mbx.PolylineAnnotationOptions(
              geometry: mbx.LineString(
                coordinates: _routePositions.sublist(0, endIndex),
              ),
              lineColor: AppColors.primaryPurple.toARGB32(),
              lineWidth: 5.0,
              lineOpacity: 1.0,
            ),
          );
          _currentAnimPolylineId = annotation.id;
        }
      }

      if (_animStep % 20 == 0) {
        debugPrint(
          '[MapManager] animation step $_animStep/$_totalAnimSteps, endIndex=$endIndex',
        );
      }
    } catch (e) {
      debugPrint('[MapManager] animation step error: $e');
    }
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Future<void> fitCameraToBounds({int retryCount = 0}) async {
    try {
      final southLat = math.min(pickupLat, dropoffLat);
      final northLat = math.max(pickupLat, dropoffLat);
      final westLon = math.min(pickupLon, dropoffLon);
      final eastLon = math.max(pickupLon, dropoffLon);

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
      debugPrint('[MapManager] camera fit succeeded');
    } catch (e) {
      debugPrint('[MapManager] camera fit failed (attempt $retryCount): $e');
      if (retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 200 * (retryCount + 1)));
        await fitCameraToBounds(retryCount: retryCount + 1);
      } else {
        debugPrint('[MapManager] camera fit failed after 3 retries');
      }
    }
  }
}
