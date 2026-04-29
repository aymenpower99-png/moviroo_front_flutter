import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Static bitmap renderers for custom map markers.
/// Copied from booking module for consistency.
abstract final class MapPainters {
  // ─── PICKUP MARKER ───────────────────────────────────────────────
  // Canvas size: 160x160
  // Filled circle diameter: 80px (radius 40)
  // White center dot diameter: 22px (radius 11)
  static Future<Uint8List> renderPickupBitmap() async {
    const sz = 160.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      40,
      Paint()..color = const Color(0xFFA855F7),
    );
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      11,
      Paint()..color = Colors.white,
    );

    final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // ─── DROP-OFF MARKER ─────────────────────────────────────────────
  // Canvas size: 80x100
  // Pin width: 80px, height: 100px
  // White center dot radius: 16px
  static Future<Uint8List> renderDropoffBitmap() async {
    const w = 80.0, h = 100.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w / 2, h, 0, h * 0.6, 0, h * 0.38)
      ..arcToPoint(Offset(w, h * 0.38), radius: Radius.circular(w / 2))
      ..cubicTo(w, h * 0.6, w / 2, h, w / 2, h)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFA855F7));
    canvas.drawCircle(
      Offset(w / 2, h * 0.38),
      16,
      Paint()..color = Colors.white,
    );

    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // ─── DRIVER MARKER — Car shape bitmap ────────────────────────────
  // Draws a car-like shape with body, windshield, and arrow direction.
  // Canvas:  200 × 200
  // The caller must rotate the PointAnnotation by the driver bearing.
  static Future<Uint8List> renderCarBitmap() async {
    const sz = 200.0;
    const cx = sz / 2;
    const cy = sz / 2;

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    // Shadow/glow effect
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(cx, cy), 55, shadowPaint);

    // Outer circle (dark purple background)
    canvas.drawCircle(
      const Offset(cx, cy),
      50,
      Paint()..color = const Color(0xFF4C1D95),
    );

    // Inner circle (lighter purple)
    canvas.drawCircle(
      const Offset(cx, cy),
      42,
      Paint()..color = const Color(0xFF6D28D9),
    );

    // Car body shape — pointing UP (north)
    final carPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Car body (rectangle with rounded corners)
    final carBody = Path()
      ..moveTo(cx - 20, cy + 15)
      ..lineTo(cx - 18, cy - 5)
      ..lineTo(cx - 12, cy - 20)
      ..lineTo(cx + 12, cy - 20)
      ..lineTo(cx + 18, cy - 5)
      ..lineTo(cx + 20, cy + 15)
      ..lineTo(cx + 15, cy + 25)
      ..lineTo(cx - 15, cy + 25)
      ..close();

    canvas.drawPath(carBody, carPaint);

    // Windshield (dark area on top of car)
    final windshieldPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;

    final windshield = Path()
      ..moveTo(cx - 10, cy - 15)
      ..lineTo(cx - 8, cy - 8)
      ..lineTo(cx + 8, cy - 8)
      ..lineTo(cx + 10, cy - 15)
      ..close();

    canvas.drawPath(windshield, windshieldPaint);

    // Headlights
    final headlightPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - 12, cy + 18), 4, headlightPaint);
    canvas.drawCircle(Offset(cx + 12, cy + 18), 4, headlightPaint);

    final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
}
