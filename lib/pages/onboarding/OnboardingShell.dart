// onboarding_shell.dart — shared layout used by all 3 steps
// Import this file in each step and call _OnboardingShell directly,
// OR keep it private (part of the same library) by placing it alongside the step files.

import 'package:flutter/material.dart';
import 'route_painter.dart';
import 'page_indicator.dart';
import '../../../../theme/app_theme.dart';

class OnboardingShell extends StatelessWidget {
  final VoidCallback onNext;
  final double carT;
  final double wheelAngle;
  final int currentStep;
  final String label;
  final String titleLine1;
  final String titleAccent;
  final String subtitle;
  final String buttonLabel;

  const OnboardingShell({
    super.key,
    required this.onNext,
    required this.carT,
    required this.wheelAngle,
    required this.currentStep,
    required this.label,
    required this.titleLine1,
    required this.titleAccent,
    required this.subtitle,
    this.buttonLabel = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP: Animated map scene ──────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: const Color(0xFFFAFAFF)),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _MapTilePainter()),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _NeighborhoodPainter()),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    right: -40,
                    height: 260,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.15, 0.9),
                          radius: 0.9,
                          colors: [
                            const Color(0xFF7C3AED).withValues(alpha: 0.08),
                            const Color(0xFFA855F7).withValues(alpha: 0.03),
                            const Color.fromARGB(0, 255, 255, 255),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -20,
                    width: 200,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFEF4444).withValues(alpha: 0.06),
                            const Color.fromARGB(0, 170, 140, 140),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RouteAndCarPainter(
                        carT: carT,
                        isDark: false,
                        wheelAngle: wheelAngle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color.fromARGB(0, 214, 179, 179),
                            AppTheme.lightBg.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── BOTTOM: Content ──────────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                color: AppTheme.lightBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryPurple,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$titleLine1\n',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F0A1E),
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: titleAccent,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryPurple,
                                height: 1.1,
                              ),
                            ),
                            const TextSpan(
                              text: ' →',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFFA855F7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6880),
                          height: 1.65,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      Center(child: PageIndicator(current: currentStep)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  buttonLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Map grid ──────────────────────────────────────────────────────────────────
class _MapTilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lp = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.045)
      ..strokeWidth = 0.8;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lp);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lp);
    }
    final dp = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.07);
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.4, dp);
      }
    }
  }

  @override
  bool shouldRepaint(_MapTilePainter old) => false;
}

// ── Neighborhood blocks ───────────────────────────────────────────────────────
class _NeighborhoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF22C55E).withValues(alpha: 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.55,
          size.height * 0.10,
          size.width * 0.30,
          size.height * 0.14,
        ),
        const Radius.circular(6),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.05,
          size.height * 0.50,
          size.width * 0.18,
          size.height * 0.10,
        ),
        const Radius.circular(6),
      ),
      p,
    );
    p.color = const Color(0xFF7C3AED).withValues(alpha: 0.055);
    for (final b in [
      [0.60, 0.28, 0.16, 0.12],
      [0.10, 0.15, 0.20, 0.10],
      [0.35, 0.40, 0.14, 0.09],
      [0.70, 0.55, 0.22, 0.14],
      [0.08, 0.68, 0.24, 0.10],
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            b[0] * size.width,
            b[1] * size.height,
            b[2] * size.width,
            b[3] * size.height,
          ),
          const Radius.circular(5),
        ),
        p,
      );
    }
    final cp = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.055);
    final path = Path();
    for (final b in [
      [0.00, 0.72, 0.07],
      [0.06, 0.62, 0.07],
      [0.12, 0.70, 0.08],
      [0.19, 0.58, 0.07],
      [0.25, 0.65, 0.08],
      [0.32, 0.60, 0.07],
      [0.38, 0.55, 0.08],
      [0.45, 0.68, 0.07],
      [0.51, 0.58, 0.08],
      [0.58, 0.63, 0.07],
      [0.64, 0.57, 0.08],
      [0.71, 0.66, 0.07],
      [0.77, 0.60, 0.08],
      [0.84, 0.70, 0.07],
      [0.90, 0.62, 0.08],
      [0.96, 0.72, 0.06],
    ]) {
      path.addRect(
        Rect.fromLTRB(
          b[0] * size.width,
          b[1] * size.height,
          (b[0] + b[2]) * size.width,
          size.height,
        ),
      );
    }
    canvas.drawPath(path, cp);
  }

  @override
  bool shouldRepaint(_NeighborhoodPainter old) => false;
}
