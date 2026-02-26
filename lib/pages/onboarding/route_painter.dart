import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared painter for all 3 onboarding steps.
/// carT: 0.0 = origin, 0.35 = midpoint (step 2 stop), 1.0 = destination (step 3)
class RouteAndCarPainter extends CustomPainter {
  final double carT;

  const RouteAndCarPainter({required this.carT});

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1.0 - t;
    return Offset(
      mt * mt * mt * p0.dx + 3 * mt * mt * t * p1.dx +
          3 * mt * t * t * p2.dx + t * t * t * p3.dx,
      mt * mt * mt * p0.dy + 3 * mt * mt * t * p1.dy +
          3 * mt * t * t * p2.dy + t * t * t * p3.dy,
    );
  }

  Offset _cubicTangent(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1.0 - t;
    return Offset(
      3 * mt * mt * (p1.dx - p0.dx) + 6 * mt * t * (p2.dx - p1.dx) +
          3 * t * t * (p3.dx - p2.dx),
      3 * mt * mt * (p1.dy - p0.dy) + 6 * mt * t * (p2.dy - p1.dy) +
          3 * t * t * (p3.dy - p2.dy),
    );
  }

  Offset _globalPoint(Size size, double g,
      Offset s1p0, Offset s1p1, Offset s1p2, Offset s1p3,
      Offset s2p0, Offset s2p1, Offset s2p2, Offset s2p3) {
    if (g <= 0.5) return _cubicPoint(s1p0, s1p1, s1p2, s1p3, g / 0.5);
    return _cubicPoint(s2p0, s2p1, s2p2, s2p3, (g - 0.5) / 0.5);
  }

  Offset _globalTangent(Size size, double g,
      Offset s1p0, Offset s1p1, Offset s1p2, Offset s1p3,
      Offset s2p0, Offset s2p1, Offset s2p2, Offset s2p3) {
    if (g <= 0.5) return _cubicTangent(s1p0, s1p1, s1p2, s1p3, g / 0.5);
    return _cubicTangent(s2p0, s2p1, s2p2, s2p3, (g - 0.5) / 0.5);
  }

  Path _subPath(Size size, double gStart, double gEnd,
      Offset s1p0, Offset s1p1, Offset s1p2, Offset s1p3,
      Offset s2p0, Offset s2p1, Offset s2p2, Offset s2p3) {
    const steps = 80;
    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final g = gStart + (gEnd - gStart) * (i / steps);
      final pt = _globalPoint(size, g, s1p0, s1p1, s1p2, s1p3, s2p0, s2p1, s2p2, s2p3);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset s1p0 = Offset(size.width * 0.22, size.height * 0.82);
    final Offset s1p1 = Offset(size.width * 0.22, size.height * 0.55);
    final Offset s1p2 = Offset(size.width * 0.55, size.height * 0.55);
    final Offset s1p3 = Offset(size.width * 0.60, size.height * 0.28);
    final Offset s2p0 = s1p3;
    final Offset s2p1 = Offset(size.width * 0.63, size.height * 0.12);
    final Offset s2p2 = Offset(size.width * 0.75, size.height * 0.12);
    final Offset s2p3 = Offset(size.width * 0.80, size.height * 0.14);

    // 1. Dim white road (full path, always visible)
    canvas.drawPath(
      _subPath(size, 0.0, 1.0, s1p0, s1p1, s1p2, s1p3, s2p0, s2p1, s2p2, s2p3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 2. Purple trail from origin → car position
    if (carT > 0.001) {
      canvas.drawPath(
        _subPath(size, 0.0, carT, s1p0, s1p1, s1p2, s1p3, s2p0, s2p1, s2p2, s2p3),
        Paint()
          ..color = const Color(0xFFB12CFF)
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. Origin dot — always purple
    canvas.drawCircle(s1p0, 5,
        Paint()..color = const Color(0xFFB12CFF).withValues(alpha: 0.9));

    // 4. Destination pin box — always visible
    {
      const double destBoxSize = 52.0;

      final destRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: s2p3, width: destBoxSize, height: destBoxSize),
        const Radius.circular(14),
      );
      // Shadow/glow
      canvas.drawRRect(
          destRRect,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // Dark fill
      canvas.drawRRect(destRRect, Paint()..color = const Color(0xFF1C1C1E));

      // Location pin icon — white
      final pinIp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(Icons.location_on_outlined.codePoint),
          style: TextStyle(
            fontSize: 26,
            fontFamily: Icons.location_on_outlined.fontFamily,
            package: Icons.location_on_outlined.fontPackage,
            color: Colors.white,
          ),
        )
        ..layout();
      pinIp.paint(canvas, s2p3 - Offset(pinIp.width / 2, pinIp.height / 2));
    }

    // 5. Car position & rotation
    final carPos = _globalPoint(size, carT, s1p0, s1p1, s1p2, s1p3, s2p0, s2p1, s2p2, s2p3);
    final tangent = _globalTangent(size, carT, s1p0, s1p1, s1p2, s1p3, s2p0, s2p1, s2p2, s2p3);
    final angle = math.atan2(tangent.dy, tangent.dx);

    // 6. Rotated car box (glow + dark fill + purple border)
    const double boxSize = 56.0;
    canvas.save();
    canvas.translate(carPos.dx, carPos.dy);
    canvas.rotate(angle - math.pi / 2);
    canvas.translate(-carPos.dx, -carPos.dy);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: carPos, width: boxSize, height: boxSize),
      const Radius.circular(14),
    );
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFFB12CFF).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFFB12CFF).withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
    canvas.restore();

    // 7. Car icon — always upright
    final ip = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.directions_car_outlined.codePoint),
        style: TextStyle(
          fontSize: 28,
          fontFamily: Icons.directions_car_outlined.fontFamily,
          package: Icons.directions_car_outlined.fontPackage,
          color: const Color(0xFFB12CFF),
        ),
      )
      ..layout();
    ip.paint(canvas, carPos - Offset(ip.width / 2, ip.height / 2));
  }

  @override
  bool shouldRepaint(covariant RouteAndCarPainter old) => old.carT != carT;
}