import 'package:flutter/material.dart';
import 'route_painter.dart';

class OnboardingStep1 extends StatelessWidget {
  final VoidCallback onNext;
  final double carT;

  const OnboardingStep1({super.key, required this.onNext, required this.carT});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B000F),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP IMAGE SECTION ────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Background gradients
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFF0B000F)),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 300,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0.3, 1.0),
                                radius: 1.2,
                                colors: [
                                  Color(0x99B12CFF),
                                  Color(0x4D6A0099),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 200,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00000000),
                                  Color(0xFF1A0030),
                                  Color(0xFF2D0050),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 80,
                          left: -60,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF6A0099).withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route + car painter (destination pin drawn inside painter)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RouteAndCarPainter(carT: carT),
                    ),
                  ),
                ],
              ),
            ),

            // ─── BOTTOM CONTENT SECTION ───────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    const Text(
                      'SMART WAY TO TRAVEL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB12CFF),
                        letterSpacing: 1.8,
                      ),
                    ),

                    const SizedBox(height: 12),

                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Book Your ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          TextSpan(
                            text: 'Ride',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB12CFF),
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Find nearby drivers instantly and book a comfortable ride in seconds. Fast, simple, and always available when you need it.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7B7B85),
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB12CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB12CFF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D3D3D),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D3D3D),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}