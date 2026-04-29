import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Displays a car marker overlay on top of the map.
/// The car is positioned at the driver's screen coordinates and rotated by the bearing.
/// Uses a styled Icon for better visibility than 3D model.
class Driver3DCar extends StatefulWidget {
  final MapboxMap mapController;
  final Point driverPosition;
  final double bearing;
  final bool visible;

  const Driver3DCar({
    super.key,
    required this.mapController,
    required this.driverPosition,
    required this.bearing,
    this.visible = true,
  });

  @override
  State<Driver3DCar> createState() => _Driver3DCarState();
}

class _Driver3DCarState extends State<Driver3DCar> {
  Offset? _screenPosition;

  @override
  void initState() {
    super.initState();
    debugPrint('🚗 Driver3DCar initState');
    _updateScreenPosition();
  }

  @override
  void didUpdateWidget(Driver3DCar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverPosition != widget.driverPosition) {
      _updateScreenPosition();
    }
  }

  Future<void> _updateScreenPosition() async {
    debugPrint('🚗 _updateScreenPosition called, visible=${widget.visible}');
    if (!widget.visible) return;

    try {
      final screenPoint = await widget.mapController.pixelForCoordinate(
        widget.driverPosition,
      );
      debugPrint('🚗 Screen position: x=${screenPoint.x}, y=${screenPoint.y}');
      if (mounted) {
        setState(() => _screenPosition = Offset(screenPoint.x, screenPoint.y));
      }
    } catch (e) {
      debugPrint('🚗 ERROR getting screen position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🚗 Driver3DCar build: visible=${widget.visible}, _screenPosition=$_screenPosition',
    );
    if (!widget.visible || _screenPosition == null) {
      debugPrint('🚗 Returning SizedBox.shrink');
      return const SizedBox.shrink();
    }

    debugPrint(
      '🚗 Rendering car at $_screenPosition with bearing ${widget.bearing}',
    );
    return Positioned(
      left: _screenPosition!.dx - 32, // Center horizontally (64px wide)
      top: _screenPosition!.dy - 32, // Center vertically (64px tall)
      child: Transform.rotate(
        angle: widget.bearing * (math.pi / 180),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF6B46C1), // Purple background
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation, // Arrow icon pointing up
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
