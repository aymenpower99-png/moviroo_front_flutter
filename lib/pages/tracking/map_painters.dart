import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Static bitmap renderers for custom map markers.
/// Reused from booking module for consistency across app.
/// Bitmaps are cached to avoid regenerating on every render.
abstract final class MapPainters {
  // ── Bitmap Cache ───────────────────────────────────────────────────
  static Uint8List? _cachedPickupBitmap;
  static Uint8List? _cachedDropoffBitmap;
  static Uint8List? _cachedDriverBitmap;

  // ─── PICKUP MARKER ───────────────────────────────────────────────
  // Canvas size: 160x160
  // Filled circle diameter: 80px (radius 40)
  // White center dot diameter: 22px (radius 11)
  static Future<Uint8List> renderPickupBitmap() async {
    if (_cachedPickupBitmap != null) {
      return _cachedPickupBitmap!;
    }

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
    _cachedPickupBitmap = (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return _cachedPickupBitmap!;
  }

  // ─── DROP-OFF MARKER ─────────────────────────────────────────────
  // Canvas size: 80x100
  // Pin width: 80px, height: 100px
  // White center dot radius: 16px
  static Future<Uint8List> renderDropoffBitmap() async {
    if (_cachedDropoffBitmap != null) {
      return _cachedDropoffBitmap!;
    }

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
    _cachedDropoffBitmap = (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return _cachedDropoffBitmap!;
  }

  // ─── DRIVER MARKER ───────────────────────────────────────────────
  // Canvas size: 200x200
  // Directional arrow pointing north (0° bearing)
  // Will be rotated based on driver bearing
  static Future<Uint8List> renderDriverBitmap() async {
    if (_cachedDriverBitmap != null) {
      return _cachedDriverBitmap!;
    }

    const sz = 200.0;
    final cx = sz / 2;
    final cy = sz / 2;

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    // Outer filled circle (primaryPurple)
    canvas.drawCircle(
      Offset(cx, cy),
      48,
      Paint()..color = const Color(0xFFA855F7),
    );

    // White ring between outer and inner
    canvas.drawCircle(Offset(cx, cy), 38, Paint()..color = Colors.white);

    // Inner filled circle (secondaryPurple)
    canvas.drawCircle(
      Offset(cx, cy),
      32,
      Paint()..color = const Color(0xFF7C3AED),
    );

    // Navigation chevron arrow — white, pointing UP (north)
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Arrow shape (chevron pointing up)
    final outer = Path()
      ..moveTo(cx, cy - 26) // tip (top)
      ..lineTo(cx - 18, cy + 16) // bottom-left
      ..lineTo(cx, cy + 6) // inner bottom-center notch
      ..lineTo(cx + 18, cy + 16) // bottom-right
      ..close();

    canvas.drawPath(outer, arrowPaint);

    final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
    _cachedDriverBitmap = (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return _cachedDriverBitmap!;
  }
}
