import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E18),
      child: CustomPaint(
        painter: MapPainter(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                AppColors.darkBg.withOpacity(0.6),
                AppColors.darkBg,
              ],
              stops: const [0, 0.5, 0.78, 1],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF2A1A4E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppColors.primaryPurple
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppColors.primaryPurple.withOpacity(0.25)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Road grid
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height * 0.3, size.height), roadPaint);
    }
    for (double i = 0; i < size.height; i += 55) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i + 20), roadPaint);
    }

    // Route path
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.12)
      ..cubicTo(
        size.width * 0.22, size.height * 0.28,
        size.width * 0.35, size.height * 0.38,
        size.width * 0.42, size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.50, size.height * 0.64,
        size.width * 0.70, size.height * 0.68,
        size.width * 0.95, size.height * 0.72,
      );

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // Origin dot
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.72),
      10,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.72),
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Destination pin
    _drawPin(canvas, Offset(size.width * 0.18, size.height * 0.12));

    // ETA cards
    _drawEtaCard(
        canvas, Offset(size.width * 0.38, size.height * 0.30), '54 min', '72 km');
    _drawEtaCard(
        canvas, Offset(size.width * 0.46, size.height * 0.46), '53 min', '71.4 km');
  }

  void _drawPin(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = const Color(0xFFFF3B6B).withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = const Color(0xFFFF3B6B)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawEtaCard(Canvas canvas, Offset pos, String time, String dist) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 88, height: 44),
      const Radius.circular(10),
    );
    canvas.drawRRect(
        rrect, Paint()..color = const Color(0xFF1C1C28)..style = PaintingStyle.fill);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF333345)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    final tp1 = TextPainter(
      text: TextSpan(
        text: '🚗 $time',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(pos.dx - tp1.width / 2, pos.dy - 14));

    final tp2 = TextPainter(
      text: TextSpan(
        text: dist,
        style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(pos.dx - tp2.width / 2, pos.dy + 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}