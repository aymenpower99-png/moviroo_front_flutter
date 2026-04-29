import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

/// Service for handling driver position animation with interpolation.
class DriverAnimationController {
  mbx.Point? _currentPos;
  mbx.Point? _targetPos;
  double _currentBearing = 0;
  double _targetBearing = 0;
  late AnimationController _animController;

  final Function(mbx.Point, double)? onPositionUpdate;
  final Function(mbx.Point)? onCameraFollow;

  DriverAnimationController({
    required TickerProvider vsync,
    this.onPositionUpdate,
    this.onCameraFollow,
  }) {
    _animController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );
    _animController.addListener(_onTick);
  }

  void setTargetPosition(mbx.Point pos, double bearing) {
    debugPrint(
      '🎬 setTargetPosition called: lat=${pos.coordinates.lat}, lng=${pos.coordinates.lng}, bearing=$bearing',
    );
    debugPrint('🎬 _currentPos is null: ${_currentPos == null}');

    // First update: snap immediately so marker is created without waiting
    // for animation tick (which would early-return because _currentPos was null).
    if (_currentPos == null) {
      debugPrint('🎬 FIRST UPDATE - snapping immediately');
      _currentPos = pos;
      _currentBearing = bearing;
      _targetPos = pos;
      _targetBearing = bearing;
      onPositionUpdate?.call(pos, bearing);
      onCameraFollow?.call(pos);
      return;
    }

    // Subsequent updates: animate from current → new target.
    // Snap _currentPos to last target so animation has a clean starting point.
    debugPrint('🎬 SUBSEQUENT UPDATE - animating');
    _currentPos = _targetPos ?? _currentPos;
    _currentBearing = _targetBearing;

    _targetPos = pos;
    _targetBearing = bearing;
    _animController.reset();
    _animController.forward();
  }

  void _onTick() {
    if (_currentPos == null || _targetPos == null) {
      debugPrint(
        '🎬 _onTick early return: _currentPos=${_currentPos == null}, _targetPos=${_targetPos == null}',
      );
      return;
    }

    final t = _animController.value;
    debugPrint('🎬 _onTick: t=$t');

    final interpolatedLat = _lerp(
      _currentPos!.coordinates.lat.toDouble(),
      _targetPos!.coordinates.lat.toDouble(),
      t,
    );
    final interpolatedLng = _lerp(
      _currentPos!.coordinates.lng.toDouble(),
      _targetPos!.coordinates.lng.toDouble(),
      t,
    );
    final interpolatedPos = mbx.Point(
      coordinates: mbx.Position(interpolatedLng, interpolatedLat),
    );

    final interpolatedBearing = _lerpAngle(_currentBearing, _targetBearing, t);

    _currentPos = interpolatedPos;
    _currentBearing = interpolatedBearing;

    onPositionUpdate?.call(interpolatedPos, interpolatedBearing);
    onCameraFollow?.call(interpolatedPos);
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  double _lerpAngle(double a, double b, double t) {
    a = a % 360;
    b = b % 360;
    double diff = b - a;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (a + diff * t) % 360;
  }

  void dispose() {
    _animController.dispose();
  }
}
