import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Static bitmap renderers for custom map markers.
/// Copied from driver app tracking system for consistency across apps.
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
    return (await img.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
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
    return (await img.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
}
