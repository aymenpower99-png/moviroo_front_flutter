import 'dart:math' as math;
import 'package:flutter/material.dart';

class RouteAndCarPainter extends CustomPainter {
  final double carT;
  final bool isDark;
  final double wheelAngle;

  const RouteAndCarPainter({
    required this.carT,
    this.isDark = false,
    this.wheelAngle = 0.0,
  });

  // ── Light mode road palette ───────────────────────────────────────────────
  static const _lightRoad = Color(0xFFBBB5EE); // lavender road — visible
  static const _lightRoadCenter = Color(0xFFD0CCFA); // centre strip lighter
  static const _lightKerb = Color(0xFFFFFFFF); // white kerb edge
  // ── Dark mode road palette ────────────────────────────────────────────────
  static const _darkRoad = Color(0xFF1A1828);
  static const _darkRoadCenter = Color(0xFF252338);

  // ── Bezier ────────────────────────────────────────────────────────────────
  static const _p0 = Offset(0.30, 0.92);
  static const _p1 = Offset(0.10, 0.52);
  static const _p2 = Offset(0.88, 0.52);
  static const _p3 = Offset(0.68, 0.08);

  Offset _b(double t) {
    final m = 1 - t;
    return _p0 * (m * m * m) +
        _p1 * (3 * m * m * t) +
        _p2 * (3 * m * t * t) +
        _p3 * (t * t * t);
  }

  Offset _bd(double t) {
    final m = 1 - t;
    return (_p1 - _p0) * (3 * m * m) +
        (_p2 - _p1) * (6 * m * t) +
        (_p3 - _p2) * (3 * t * t);
  }

  Offset _perp(double t, double dist, Size size) {
    final d = _bd(t);
    final len = math.sqrt(
      (d.dx * size.width) * (d.dx * size.width) +
          (d.dy * size.height) * (d.dy * size.height),
    );
    if (len == 0) return Offset.zero;
    return Offset(
      -d.dy * size.height / len * dist,
      d.dx * size.width / len * dist,
    );
  }

  Path _fullPath(Size s) => Path()
    ..moveTo(_p0.dx * s.width, _p0.dy * s.height)
    ..cubicTo(
      _p1.dx * s.width,
      _p1.dy * s.height,
      _p2.dx * s.width,
      _p2.dy * s.height,
      _p3.dx * s.width,
      _p3.dy * s.height,
    );

  Path _pathUpTo(Size s, double t) {
    final p01 = Offset.lerp(_p0, _p1, t)!;
    final p12 = Offset.lerp(_p1, _p2, t)!;
    final p23 = Offset.lerp(_p2, _p3, t)!;
    final p012 = Offset.lerp(p01, p12, t)!;
    final p123 = Offset.lerp(p12, p23, t)!;
    final end = Offset.lerp(p012, p123, t)!;
    return Path()
      ..moveTo(_p0.dx * s.width, _p0.dy * s.height)
      ..cubicTo(
        p01.dx * s.width,
        p01.dy * s.height,
        p012.dx * s.width,
        p012.dy * s.height,
        end.dx * s.width,
        end.dy * s.height,
      );
  }

  // ── POIs ──────────────────────────────────────────────────────────────────
  static const _pois = [
    [0.18, 1.0, 0.28, 'Restaurant', 0xe532, 0xFFFF6B6B],
    [0.35, -1.0, 0.28, 'Hotel', 0xe549, 0xFF3B82F6],
    [0.82, 1.0, 0.18, 'Mall', 0xe59c, 0xFFF59E0B],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawMapGrid(canvas, size);
    _drawAllConnectors(canvas, size);

    final road = _fullPath(size);
    final roadW = size.width * 0.17;

    // ── Road glow shadow ──────────────────────────────────────────────────
    canvas.drawPath(
      road,
      Paint()
        ..color = (isDark ? Colors.black : const Color(0xFF7C3AED)).withValues(
          alpha: isDark ? 0.45 : 0.14,
        )
        ..strokeWidth = roadW + size.width * 0.06
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.032),
    );

    // ── Road shoulder ─────────────────────────────────────────────────────
    canvas.drawPath(
      road,
      Paint()
        ..color = isDark ? const Color(0xFF252338) : const Color(0xFFCCC8F0)
        ..strokeWidth = roadW + 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Main asphalt ──────────────────────────────────────────────────────
    canvas.drawPath(
      road,
      Paint()
        ..color = isDark ? _darkRoad : _lightRoad
        ..strokeWidth = roadW
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Center lighter strip ──────────────────────────────────────────────
    canvas.drawPath(
      road,
      Paint()
        ..color = (isDark ? _darkRoadCenter : _lightRoadCenter).withValues(
          alpha: 0.50,
        )
        ..strokeWidth = roadW * 0.46
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Kerb edge lines ───────────────────────────────────────────────────
    _drawKerb(canvas, size, roadW, right: false);
    _drawKerb(canvas, size, roadW, right: true);

    // ── Center dashes ─────────────────────────────────────────────────────
    _drawCenterDash(canvas, size);

    // ── Trail ─────────────────────────────────────────────────────────────
    if (carT > 0.005) {
      final trail = _pathUpTo(size, carT.clamp(0.0, 1.0));
      canvas.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFFA855F7).withValues(alpha: 0.30)
          ..strokeWidth = roadW * 0.56
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.018),
      );
      canvas.drawPath(
        trail,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF7C3AED).withValues(alpha: 0.55),
              const Color(0xFFA855F7),
              const Color(0xFFD946EF),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..strokeWidth = size.width * 0.020
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        trail,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = size.width * 0.004
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Destination bubble ────────────────────────────────────────────────
    final dPos = _b(1.0);
    _drawEndpointBubble(
      canvas,
      Offset(dPos.dx * size.width, dPos.dy * size.height),
      const Color(0xFFEF4444),
      size,
      label: 'Destination',
      iconCode: 0xe0c8,
      bubbleDx: -size.width * 0.26,
      bubbleDy: 0,
    );

    // ── Car ───────────────────────────────────────────────────────────────
    final t = carT.clamp(0.0, 1.0);
    final cp = _b(t);
    final cd = _bd(t);
    final angle =
        math.atan2(cd.dy * size.height, cd.dx * size.width) - math.pi / 2;
    _drawCar(
      canvas,
      Offset(cp.dx * size.width, cp.dy * size.height),
      angle,
      size,
    );

    // ── POI + Origin bubbles ──────────────────────────────────────────────
    _drawPOIBubbles(canvas, size);
  }

  void _drawMapGrid(Canvas canvas, Size size) {
    final lp = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.07 : 0.045)
      ..strokeWidth = 0.8;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lp);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lp);
    }
    final dp = Paint()
      ..color = const Color(
        0xFF7C3AED,
      ).withValues(alpha: isDark ? 0.12 : 0.075);
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dp);
      }
    }
    for (final z in [
      [0.55, 0.06, 0.28, 0.13, 0xFF22C55E],
      [0.05, 0.08, 0.20, 0.11, 0xFF7C3AED],
      [0.62, 0.35, 0.26, 0.11, 0xFF7C3AED],
      [0.04, 0.44, 0.18, 0.09, 0xFF22C55E],
      [0.68, 0.60, 0.22, 0.11, 0xFF7C3AED],
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            z[0] * size.width,
            z[1] * size.height,
            z[2] * size.width,
            z[3] * size.height,
          ),
          const Radius.circular(5),
        ),
        Paint()
          ..color = Color(
            z[4].toInt(),
          ).withValues(alpha: isDark ? 0.10 : 0.062),
      );
    }
  }

  void _drawKerb(
    Canvas canvas,
    Size size,
    double roadW, {
    required bool right,
  }) {
    final sign = right ? 1.0 : -1.0;
    final dist = roadW * 0.49;
    final path = Path();
    for (int i = 0; i <= 80; i++) {
      final t = i / 80.0;
      final pos = _b(t);
      final perp = _perp(t, dist * sign, size);
      final px = pos.dx * size.width + perp.dx;
      final py = pos.dy * size.height + perp.dy;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.22)
            : _lightKerb.withValues(alpha: 0.70)
        ..strokeWidth = isDark ? 1.6 : 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCenterDash(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.38)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < 30; i += 2) {
      final a = _b(i / 30.0);
      final b = _b(math.min((i + 0.75) / 30.0, 1.0));
      canvas.drawLine(
        Offset(a.dx * size.width, a.dy * size.height),
        Offset(b.dx * size.width, b.dy * size.height),
        paint,
      );
    }
  }

  void _drawAllConnectors(Canvas canvas, Size size) {
    for (final poi in _pois) {
      final roadT = (poi[0] as num).toDouble();
      final side = (poi[1] as num).toDouble();
      final dist = (poi[2] as num).toDouble();
      final color = Color((poi[5] as num).toInt());
      _connector(
        canvas,
        size,
        roadT: roadT,
        sideSign: side,
        distFrac: dist,
        color: color,
        thick: false,
      );
    }
    _connector(
      canvas,
      size,
      roadT: 0.0,
      sideSign: -1.0,
      distFrac: 0.36,
      color: const Color(0xFF22C55E),
      thick: true,
    );
    _connectorToFixed(
      canvas,
      size,
      roadT: 1.0,
      bubblePx: Offset(
        _b(1.0).dx * size.width - size.width * 0.26,
        _b(1.0).dy * size.height,
      ),
      color: const Color(0xFFEF4444),
    );
  }

  void _connector(
    Canvas canvas,
    Size size, {
    required double roadT,
    required double sideSign,
    required double distFrac,
    required Color color,
    required bool thick,
  }) {
    final rp = _b(roadT);
    final perp = _perp(roadT, size.width * distFrac * sideSign, size);
    final rPx = Offset(rp.dx * size.width, rp.dy * size.height);
    final bPx = rPx + perp;
    _dashedLine(
      canvas,
      rPx,
      bPx,
      Paint()
        ..color = color.withValues(alpha: thick ? 0.42 : 0.28)
        ..strokeWidth = thick ? 1.2 : 1.0
        ..strokeCap = StrokeCap.round,
    );
    if (thick) {
      canvas.drawCircle(
        rPx,
        4.0,
        Paint()
          ..color = color.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawCircle(
      rPx,
      thick ? 3.0 : 2.8,
      Paint()..color = color.withValues(alpha: thick ? 1.0 : 0.40),
    );
    canvas.drawCircle(rPx, thick ? 1.8 : 1.6, Paint()..color = Colors.white);
  }

  void _connectorToFixed(
    Canvas canvas,
    Size size, {
    required double roadT,
    required Offset bubblePx,
    required Color color,
  }) {
    final rp = _b(roadT);
    final rPx = Offset(rp.dx * size.width, rp.dy * size.height);
    _dashedLine(
      canvas,
      rPx,
      bubblePx,
      Paint()
        ..color = color.withValues(alpha: 0.42)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      rPx,
      4.0,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(rPx, 3.0, Paint()..color = color);
    canvas.drawCircle(rPx, 1.8, Paint()..color = Colors.white);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final l = math.sqrt(dx * dx + dy * dy);
    if (l == 0) return;
    const dash = 5.0, gap = 4.0;
    double s = 0;
    final ux = dx / l, uy = dy / l;
    while (s < l) {
      final e = math.min(s + dash, l);
      canvas.drawLine(
        Offset(a.dx + ux * s, a.dy + uy * s),
        Offset(a.dx + ux * e, a.dy + uy * e),
        paint,
      );
      s += dash + gap;
    }
  }

  void _drawPOIBubbles(Canvas canvas, Size size) {
    for (final poi in _pois) {
      final rp = _b((poi[0] as num).toDouble());
      final perp = _perp(
        (poi[0] as num).toDouble(),
        size.width * (poi[2] as num).toDouble() * (poi[1] as num).toDouble(),
        size,
      );
      final center = Offset(rp.dx * size.width, rp.dy * size.height) + perp;
      _bubble(
        canvas,
        center,
        size.width * 0.070,
        Color((poi[5] as num).toInt()),
        (poi[4] as num).toInt(),
        poi[3] as String,
        size,
        bold: false,
      );
    }
    final oRp = _b(0.0);
    final oPerp = _perp(0.0, size.width * 0.36 * -1.0, size);
    final oC = Offset(oRp.dx * size.width, oRp.dy * size.height) + oPerp;
    _bubble(
      canvas,
      oC,
      size.width * 0.085,
      const Color(0xFF22C55E),
      0xe55f,
      'My Location',
      size,
      bold: true,
    );
  }

  void _bubble(
    Canvas canvas,
    Offset center,
    double r,
    Color color,
    int iconCode,
    String label,
    Size size, {
    required bool bold,
  }) {
    canvas.drawCircle(
      center,
      r * 1.5,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.65),
    );
    canvas.drawCircle(
      center + Offset(0, r * 0.18),
      r * 1.02,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [color, color.withValues(alpha: 0.30), color],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..strokeWidth = bold ? 2.5 : 1.8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      r * 0.58,
      Paint()..color = color.withValues(alpha: bold ? 0.12 : 0.07),
    );
    final ip = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconCode),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: r * (bold ? 0.86 : 0.78),
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ip.paint(canvas, center - Offset(ip.width / 2, ip.height / 2));

    final lp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: size.width * (bold ? 0.027 : 0.022),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: bold
              ? color
              : (isDark
                    ? Colors.white.withValues(alpha: 0.80)
                    : const Color(0xFF1A1828).withValues(alpha: 0.72)),
          letterSpacing: 0.15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = center.dx - lp.width / 2;
    final ly = center.dy + r + 4;
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(lx - 5, ly - 2, lp.width + 10, lp.height + 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      pill,
      Paint()
        ..color = bold
            ? color.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.88),
    );
    if (bold) {
      canvas.drawRRect(
        pill,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
    lp.paint(canvas, Offset(lx, ly));
  }

  void _drawEndpointBubble(
    Canvas canvas,
    Offset roadPt,
    Color color,
    Size size, {
    required String label,
    required int iconCode,
    double bubbleDx = 0,
    double bubbleDy = 0,
  }) {
    final center = Offset(roadPt.dx + bubbleDx, roadPt.dy + bubbleDy);
    _bubble(
      canvas,
      center,
      size.width * 0.085,
      color,
      iconCode,
      label,
      size,
      bold: true,
    );
  }

  void _drawCar(Canvas canvas, Offset center, double angle, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final cw = size.width * 0.092;
    final ch = cw * 1.78;
    final cr = cw * 0.22;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(2, ch * 0.18),
        width: cw * 1.55,
        height: ch * 0.18,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.30 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawPath(
      Path()
        ..moveTo(-cw * 0.50, -ch * 0.42)
        ..lineTo(-cw * 0.50, ch * 0.42)
        ..lineTo(-cw * 0.57, ch * 0.37)
        ..lineTo(-cw * 0.57, -ch * 0.37)
        ..close(),
      Paint()..color = const Color(0xFF3B1E7A).withValues(alpha: 0.85),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cw * 0.50, -ch * 0.42)
        ..lineTo(cw * 0.50, ch * 0.42)
        ..lineTo(cw * 0.57, ch * 0.37)
        ..lineTo(cw * 0.57, -ch * 0.37)
        ..close(),
      Paint()..color = const Color(0xFF9B6EF5).withValues(alpha: 0.55),
    );

    const body = Color(0xFF7C3AED);
    final br = Rect.fromCenter(center: Offset.zero, width: cw, height: ch);
    canvas.drawRRect(
      RRect.fromRectAndRadius(br, Radius.circular(cr)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(body, Colors.white, 0.28)!,
            body,
            Color.lerp(body, Colors.black, 0.20)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(br),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -ch * 0.04),
          width: cw * 0.68,
          height: ch * 0.38,
        ),
        Radius.circular(cr * 0.75),
      ),
      Paint()..color = const Color(0xFF0D0B1E).withValues(alpha: 0.85),
    );

    final fg = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -ch * 0.21),
        width: cw * 0.58,
        height: ch * 0.155,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      fg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB8D8F0).withValues(alpha: 0.96),
            const Color(0xFF5A9FCE).withValues(alpha: 0.75),
          ],
        ).createShader(fg.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-cw * 0.22, -ch * 0.278, cw * 0.08, ch * 0.08),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, ch * 0.22),
          width: cw * 0.54,
          height: ch * 0.115,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3A6B90).withValues(alpha: 0.50),
    );

    for (final s in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * cw * 0.35, -ch * 0.040),
            width: cw * 0.11,
            height: ch * 0.18,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF3A6B90).withValues(alpha: 0.40),
      );
    }

    for (final s in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(s * cw * 0.545, -ch * 0.165),
            width: cw * 0.12,
            height: ch * 0.065,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF4C1D95),
      );
    }

    for (final wp in [
      Offset(-cw * 0.47, -ch * 0.305),
      Offset(cw * 0.47, -ch * 0.305),
      Offset(-cw * 0.47, ch * 0.305),
      Offset(cw * 0.47, ch * 0.305),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: wp + const Offset(1.2, 2.0),
            width: cw * 0.195,
            height: ch * 0.150,
          ),
          Radius.circular(cw * 0.04),
        ),
        Paint()
          ..color = const Color.fromARGB(
            255,
            255,
            235,
            235,
          ).withValues(alpha: 0.45),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: wp, width: cw * 0.195, height: ch * 0.150),
          Radius.circular(cw * 0.05),
        ),
        Paint()..color = const Color.fromARGB(255, 203, 201, 235),
      );
      canvas.drawCircle(
        wp,
        cw * 0.068,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.80),
              const Color(0xFFAAAAAE),
              const Color(0xFF606070),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(Rect.fromCircle(center: wp, radius: cw * 0.068)),
      );
      for (int i = 0; i < 5; i++) {
        final a = wheelAngle + i * math.pi * 2 / 5;
        canvas.drawLine(
          wp,
          wp + Offset(math.cos(a) * cw * 0.055, math.sin(a) * cw * 0.055),
          Paint()
            ..color = const Color(0xFF888898)
            ..strokeWidth = 0.9,
        );
      }
      canvas.drawCircle(
        wp,
        cw * 0.022,
        Paint()..color = const Color(0xFFA78BFA).withValues(alpha: 0.90),
      );
    }

    for (final s in [-1.0, 1.0]) {
      final h = Offset(s * cw * 0.28, -ch * 0.485);
      canvas.drawCircle(
        h,
        cw * 0.12,
        Paint()
          ..color = const Color(0xFFFDE68A).withValues(alpha: 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: h, width: cw * 0.17, height: cw * 0.052),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFF7CC).withValues(alpha: 0.96),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: h + Offset(0, cw * 0.045),
          width: cw * 0.13,
          height: cw * 0.060,
        ),
        Paint()..color = const Color(0xFFFFEDA0).withValues(alpha: 0.78),
      );
    }

    for (final s in [-1.0, 1.0]) {
      final tl = Offset(s * cw * 0.28, ch * 0.485);
      canvas.drawCircle(
        tl,
        cw * 0.10,
        Paint()
          ..color = const Color(0xFFFF2244).withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: tl, width: cw * 0.16, height: cw * 0.050),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFF3355).withValues(alpha: 0.90),
      );
    }

    canvas.drawLine(
      Offset(-cw * 0.46, 0),
      Offset(cw * 0.46, 0),
      Paint()
        ..color = const Color(0xFFA78BFA).withValues(alpha: 0.22)
        ..strokeWidth = 0.9,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -ch * 0.052),
          width: cw * 0.26,
          height: ch * 0.030,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = const Color(0xFFA78BFA).withValues(alpha: 0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    for (int i = -2; i <= 2; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(i * cw * 0.042, -ch * 0.052),
          width: cw * 0.026,
          height: ch * 0.016,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.70),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(RouteAndCarPainter old) =>
      old.carT != carT || old.isDark != isDark || old.wheelAngle != wheelAngle;
}
