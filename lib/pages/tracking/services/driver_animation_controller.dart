import 'package:flutter/material.dart';
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
    _targetPos = pos;
    _targetBearing = bearing;
    _animController.reset();
    _animController.forward();
  }

  void _onTick() {
    if (_currentPos == null || _targetPos == null) return;

    final t = _animController.value;

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
