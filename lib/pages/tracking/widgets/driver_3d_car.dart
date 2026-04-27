import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart' show ModelViewer;

/// 3D car widget overlay for tracking map.
/// Uses ModelViewerPlus to render the 3D car model at the driver's position.
class Driver3DCar extends StatefulWidget {
  final MapLibreMapController mapController;
  final LatLng driverPosition;
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
    if (!widget.visible) {
      setState(() => _screenPosition = null);
      return;
    }

    try {
      final screenPoint = await widget.mapController.toScreenLocation(
        widget.driverPosition,
      );
      setState(
        () => _screenPosition = Offset(
          screenPoint.x.toDouble(),
          screenPoint.y.toDouble(),
        ),
      );
    } catch (e) {
      debugPrint('Error converting LatLng to screen position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || _screenPosition == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _screenPosition!.dx - 40, // Center horizontally (80px wide)
      top: _screenPosition!.dy - 40, // Center vertically (80px tall)
      child: SizedBox(
        width: 80,
        height: 80,
        child: Transform.rotate(
          angle: widget.bearing * (math.pi / 180), // Convert degrees to radians
          child: const ModelViewer(
            src: 'images/3d/car.glb',
            autoRotate: false,
            disableZoom: true,
            disablePan: true,
            disableTap: true,
            backgroundColor: Colors.transparent,
            cameraControls: false,
          ),
        ),
      ),
    );
  }
}
