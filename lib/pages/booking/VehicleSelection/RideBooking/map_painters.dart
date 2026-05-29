import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Static bitmap renderers for custom map markers.
/// Compact icons — small circle for pickup, sharp square for dropoff.
abstract final class MapPainters {
  // ─── PICKUP MARKER ───────────────────────────────────────────────
  // Canvas: 80x80. Purple circle radius 22, white center dot radius 8.
  static Future<Uint8List> renderPickupBitmap() async {
    const sz = 80.0;
    const c = Offset(40.0, 40.0);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    // Drop shadow
    canvas.drawCircle(
      c + const Offset(0, 2),
      22,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Purple fill
    canvas.drawCircle(c, 22, Paint()..color = const Color(0xFFA855F7));
    // White center
    canvas.drawCircle(c, 8, Paint()..color = Colors.white);

    final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // ─── DROP-OFF MARKER ─────────────────────────────────────────────
  // Canvas: 80x80. Sharp purple square (no rounded corners), white center dot.
  static Future<Uint8List> renderDropoffBitmap() async {
    const sz = 80.0;
    const pad = 18.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    // Drop shadow
    canvas.drawRect(
      Rect.fromLTWH(pad + 1, pad + 3, sz - pad * 2, sz - pad * 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Solid purple square — sharp corners (BorderRadius.zero)
    canvas.drawRect(
      Rect.fromLTWH(pad, pad, sz - pad * 2, sz - pad * 2),
      Paint()..color = const Color(0xFFA855F7),
    );
    // White center dot
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      7,
      Paint()..color = Colors.white,
    );

    final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
}
