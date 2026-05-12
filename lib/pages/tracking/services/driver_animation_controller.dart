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
/// - **Predictive extrapolation**: when a segment ends with no queued GPS,
///   the car continues moving forward along its bearing at the last known
///   speed. Real GPS updates interrupt predictions, so the car smoothly
///   redirects to the actual position when new data arrives.
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
  double _queuedSpeedKmh = 0;

  // Whether the current segment is a prediction (no real GPS target)
  bool _isPredicting = false;

  // Last known driver speed from WebSocket (km/h → converted to m/s internally)
  double _lastSpeedMps = _defaultSpeedMps;

  // Track how many consecutive predictions we've made (cap to avoid runaway)
  int _predictionCount = 0;

  late AnimationController _animController;

  // Tunables ────────────────────────────────────────────────────────────────
  /// Ignore GPS deltas smaller than this (meters) — prevents micro-jitter.
  static const double _jitterThresholdMeters = 2.0;

  /// Min animation duration (very small movements).
  static const int _minDurationMs = 300;

  /// Max animation duration — should be close to GPS update interval (~5s)
  /// so the car is always moving smoothly between updates.
  static const int _maxDurationMs = 4500;

  /// Default average speed when no WebSocket speed available: ~10 m/s (~36 km/h).
  static const double _defaultSpeedMps = 10.0;

  /// Minimum speed threshold (m/s). Below this the driver is considered
  /// stopped — no predictive extrapolation will run.
  static const double _stoppedThresholdMps = 1.5;

  /// How far ahead (meters) each predictive segment projects.
  static const double _predictionDistanceMeters = 25.0;

  /// Max consecutive predictions before we stop (safety cap).
  static const int _maxPredictions = 4;

  /// Duration of each predictive segment (ms).
  static const int _predictionDurationMs = 2000;

  /// Bearing smoothing factor (0 = no smoothing, 1 = freeze bearing).
  /// Lower = more responsive, higher = smoother rotation.
  static const double _bearingSmoothFactor = 0.3;

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
  /// [speedKmh] is the driver speed from the WebSocket data (km/h).
  void setTargetPosition(mbx.Point pos, double bearing, {double speedKmh = 0}) {
    // Update last known speed
    if (speedKmh > 0) {
      _lastSpeedMps = speedKmh / 3.6;
    }

    // ── First update: render immediately (no animation source yet) ────────
    if (_currentPos == null) {
      debugPrint('🎬 FIRST UPDATE - rendering immediately');
      _currentPos = pos;
      _currentBearing = bearing;
      _segmentStart = pos;
      _segmentEnd = pos;
      _segmentStartBearing = bearing;
      _segmentEndBearing = bearing;
      _isPredicting = false;
      _predictionCount = 0;
      onPositionUpdate?.call(pos, bearing);
      onCameraFollow?.call(pos);
      return;
    }

    // ── Jitter filter: ignore tiny GPS drifts ─────────────────────────────
    final referencePos = _isPredicting
        ? _currentPos!
        : (_segmentEnd ?? _currentPos!);
    final distance = _distanceMeters(referencePos, pos);
    if (distance < _jitterThresholdMeters) {
      debugPrint(
        '🎬 JITTER SKIP — ${distance.toStringAsFixed(2)}m < ${_jitterThresholdMeters}m',
      );
      return;
    }

    // Reset prediction counter — we got a real GPS fix
    _predictionCount = 0;

    // ── If currently predicting, interrupt and redirect to real position ──
    if (_isPredicting && _animController.isAnimating) {
      debugPrint('🎬 INTERRUPT PREDICTION — redirecting to real GPS');
      _isPredicting = false;
      _animController.stop();
      _startSegment(pos, bearing, isPrediction: false);
      return;
    }

    // ── If animation running, queue the new target (don't reset!) ─────────
    if (_animController.isAnimating) {
      debugPrint('🎬 QUEUE - animation running, queue new target');
      _queuedPos = pos;
      _queuedBearing = bearing;
      _queuedSpeedKmh = speedKmh;
      return;
    }

    // ── Otherwise start a fresh segment from current interpolated pos ─────
    _startSegment(pos, bearing, isPrediction: false);
  }

  /// Begin animating from current interpolated position to the given target.
  void _startSegment(
    mbx.Point target,
    double targetBearing, {
    required bool isPrediction,
  }) {
    _segmentStart = _currentPos;
    _segmentStartBearing = _currentBearing;
    _segmentEnd = target;
    _segmentEndBearing = targetBearing;
    _isPredicting = isPrediction;

    final distance = _distanceMeters(_segmentStart!, _segmentEnd!);

    int durationMs;
    if (isPrediction) {
      durationMs = _predictionDurationMs;
    } else {
      final speed = _lastSpeedMps > _stoppedThresholdMps
          ? _lastSpeedMps
          : _defaultSpeedMps;
      durationMs = (distance / speed * 1000)
          .clamp(_minDurationMs.toDouble(), _maxDurationMs.toDouble())
          .toInt();
    }
    _animController.duration = Duration(milliseconds: durationMs);

    debugPrint(
      '🎬 START ${isPrediction ? "PREDICTION" : "SEGMENT"} — distance=${distance.toStringAsFixed(1)}m, duration=${durationMs}ms, speed=${_lastSpeedMps.toStringAsFixed(1)}m/s',
    );
    _animController.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // If a target was queued during this segment, start the next one.
    if (_queuedPos != null) {
      final next = _queuedPos!;
      final nextB = _queuedBearing;
      final nextSpeed = _queuedSpeedKmh;
      _queuedPos = null;
      _predictionCount = 0;
      if (nextSpeed > 0) _lastSpeedMps = nextSpeed / 3.6;
      _startSegment(next, nextB, isPrediction: false);
      return;
    }

    // ── Predictive extrapolation ──────────────────────────────────────────
    // No queued target and driver was moving → project forward so the car
    // keeps gliding instead of freezing.
    if (_lastSpeedMps >= _stoppedThresholdMps &&
        _predictionCount < _maxPredictions &&
        _currentPos != null) {
      _predictionCount++;
      final predictedPos = _projectForward(
        _currentPos!,
        _currentBearing,
        _predictionDistanceMeters,
      );
      debugPrint(
        '🎬 PREDICT #$_predictionCount — bearing=${_currentBearing.toStringAsFixed(1)}°, dist=${_predictionDistanceMeters}m',
      );
      _startSegment(predictedPos, _currentBearing, isPrediction: true);
    }
  }

  void _onTick() {
    if (_segmentStart == null || _segmentEnd == null) return;

    // Use linear curve for predictions (constant speed feel),
    // easeInOutCubic for real GPS segments (natural acceleration/deceleration).
    final t = _isPredicting
        ? _animController.value
        : Curves.easeInOutCubic.transform(_animController.value);

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

  /// Project a point forward by [distanceMeters] along [bearingDeg].
  mbx.Point _projectForward(
    mbx.Point from,
    double bearingDeg,
    double distanceMeters,
  ) {
    const earthRadius = 6371000.0;
    final lat1 = from.coordinates.lat.toDouble() * math.pi / 180;
    final lng1 = from.coordinates.lng.toDouble() * math.pi / 180;
    final brng = bearingDeg * math.pi / 180;
    final angDist = distanceMeters / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angDist) +
          math.cos(lat1) * math.sin(angDist) * math.cos(brng),
    );
    final lng2 =
        lng1 +
        math.atan2(
          math.sin(brng) * math.sin(angDist) * math.cos(lat1),
          math.cos(angDist) - math.sin(lat1) * math.sin(lat2),
        );

    return mbx.Point(
      coordinates: mbx.Position(lng2 * 180 / math.pi, lat2 * 180 / math.pi),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _lerpAngle(double a, double b, double t) {
    a = a % 360;
    b = b % 360;
    double diff = b - a;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    // Apply smoothing: ease rotation more gently than position
    final smoothT =
        t * (1.0 - _bearingSmoothFactor) + (t * t) * _bearingSmoothFactor;
    return (a + diff * smoothT) % 360;
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
