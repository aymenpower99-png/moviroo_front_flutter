import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Service for handling driver position animation with smooth interpolation.
///
/// Key design decisions for smooth Uber-like movement:
/// - Uses a queue for incoming GPS updates so animations are never reset mid-flight
/// - Anchors animation start from CURRENT interpolated position (no snapping)
/// - Velocity-based duration: short distances = fast, long distances = slow
/// - Ignores tiny GPS jitter (<1m) to prevent micro-jitters when stationary
class DriverAnimationController {
  // Current interpolated position (what's rendered NOW)
  mbx.Point? _currentPos;
  double _currentBearing = 0;

  // Animation segment: animating from _segmentStart -> _segmentEnd
  mbx.Point? _segmentStart;
  mbx.Point? _segmentEnd;
  double _segmentStartBearing = 0;
  double _segmentEndBearing = 0;

  // Queued next target (set while an animation is running)
  mbx.Point? _queuedPos;
  double _queuedBearing = 0;

  late AnimationController _animController;

  // Tunables ────────────────────────────────────────────────────────────────
  /// Ignore GPS deltas smaller than this (meters) — prevents micro-jitter.
  static const double _jitterThresholdMeters = 1.0;

  /// Min animation duration (very small movements).
  static const int _minDurationMs = 250;

  /// Max animation duration (large GPS jumps shouldn't take forever).
  static const int _maxDurationMs = 1500;

  /// Assumed average speed for duration calc: ~10 m/s (~36 km/h urban).
  static const double _assumedSpeedMps = 10.0;

  final Function(mbx.Point, double)? onPositionUpdate;
  final Function(mbx.Point)? onCameraFollow;

  DriverAnimationController({
    required TickerProvider vsync,
    this.onPositionUpdate,
    this.onCameraFollow,
  }) {
    _animController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: _minDurationMs),
    );
    _animController.addListener(_onTick);
    _animController.addStatusListener(_onStatus);
  }

  /// Feed a new GPS target into the animation pipeline.
  void setTargetPosition(mbx.Point pos, double bearing) {
    // ── First update: render immediately (no animation source yet) ────────
    if (_currentPos == null) {
      debugPrint('🎬 FIRST UPDATE - rendering immediately');
      _currentPos = pos;
      _currentBearing = bearing;
      _segmentStart = pos;
      _segmentEnd = pos;
      _segmentStartBearing = bearing;
      _segmentEndBearing = bearing;
      onPositionUpdate?.call(pos, bearing);
      onCameraFollow?.call(pos);
      return;
    }

    // ── Jitter filter: ignore tiny GPS drifts ─────────────────────────────
    final referencePos = _segmentEnd ?? _currentPos!;
    final distance = _distanceMeters(referencePos, pos);
    if (distance < _jitterThresholdMeters) {
      debugPrint(
        '🎬 JITTER SKIP — ${distance.toStringAsFixed(2)}m < ${_jitterThresholdMeters}m',
      );
      return;
    }

    // ── If animation running, queue the new target (don't reset!) ─────────
    if (_animController.isAnimating) {
      debugPrint('🎬 QUEUE - animation running, queue new target');
      _queuedPos = pos;
      _queuedBearing = bearing;
      return;
    }

    // ── Otherwise start a fresh segment from current interpolated pos ─────
    _startSegment(pos, bearing);
  }

  /// Begin animating from current interpolated position to the given target.
  void _startSegment(mbx.Point target, double targetBearing) {
    _segmentStart = _currentPos;
    _segmentStartBearing = _currentBearing;
    _segmentEnd = target;
    _segmentEndBearing = targetBearing;

    final distance = _distanceMeters(_segmentStart!, _segmentEnd!);
    final durationMs = (distance / _assumedSpeedMps * 1000)
        .clamp(_minDurationMs.toDouble(), _maxDurationMs.toDouble())
        .toInt();
    _animController.duration = Duration(milliseconds: durationMs);

    debugPrint(
      '🎬 START SEGMENT — distance=${distance.toStringAsFixed(1)}m, duration=${durationMs}ms',
    );
    _animController.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // If a target was queued during this segment, start the next one.
    if (_queuedPos != null) {
      final next = _queuedPos!;
      final nextB = _queuedBearing;
      _queuedPos = null;
      _startSegment(next, nextB);
    }
  }

  void _onTick() {
    if (_segmentStart == null || _segmentEnd == null) return;

    final t = Curves.linear.transform(_animController.value);

    final interpolatedLat = _lerp(
      _segmentStart!.coordinates.lat.toDouble(),
      _segmentEnd!.coordinates.lat.toDouble(),
      t,
    );
    final interpolatedLng = _lerp(
      _segmentStart!.coordinates.lng.toDouble(),
      _segmentEnd!.coordinates.lng.toDouble(),
      t,
    );
    final interpolatedPos = mbx.Point(
      coordinates: mbx.Position(interpolatedLng, interpolatedLat),
    );

    final interpolatedBearing = _lerpAngle(
      _segmentStartBearing,
      _segmentEndBearing,
      t,
    );

    _currentPos = interpolatedPos;
    _currentBearing = interpolatedBearing;

    onPositionUpdate?.call(interpolatedPos, interpolatedBearing);
    onCameraFollow?.call(interpolatedPos);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _lerpAngle(double a, double b, double t) {
    a = a % 360;
    b = b % 360;
    double diff = b - a;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (a + diff * t) % 360;
  }

  /// Haversine distance in meters.
  double _distanceMeters(mbx.Point a, mbx.Point b) {
    const earthRadius = 6371000.0;
    final lat1 = a.coordinates.lat.toDouble() * math.pi / 180;
    final lat2 = b.coordinates.lat.toDouble() * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng =
        (b.coordinates.lng.toDouble() - a.coordinates.lng.toDouble()) *
        math.pi /
        180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  void dispose() {
    _animController.dispose();
  }
}
