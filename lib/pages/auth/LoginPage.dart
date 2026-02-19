import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Color(0xFF4A4A55),
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF7B7B85), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB12CFF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ── App Icon ──────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFB12CFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),

              const SizedBox(height: 28),

              // ── Title & subtitle ──────────────────────────────────
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sign in to access your premium ride transfers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7B7B85),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // ── Email ─────────────────────────────────────────────
              _label('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7B7B85),
                ),
                decoration: _fieldDecoration(
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────────
              _label('PASSWORD'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7B7B85),
                ),
                decoration: _fieldDecoration(
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF7B7B85),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Forgot Password ───────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB12CFF),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Sign In Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB12CFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Divider ───────────────────────────────────────────
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF2C2C2E))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A55),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF2C2C2E))),
                ],
              ),

              const SizedBox(height: 20),

              // ── Google ────────────────────────────────────────────
              _socialButton(
                onPressed: () {},
                backgroundColor: const Color(0xFF1C1C1E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleIcon(),
                    const SizedBox(width: 12),
                    const Text(
                      'Google',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Apple ─────────────────────────────────────────────
              _socialButton(
                onPressed: () {},
                backgroundColor: Colors.white,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.black, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Apple',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Don't have an account? ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF7B7B85),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB12CFF),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7B7B85),
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _socialButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Widget child,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      );
}

/// Google 'G' colored icon using a simple RichText trick
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width;
    final sh = size.height;

    // Draw 4 colored quadrant arcs to simulate the Google G
    final segments = [
      // [startAngle degrees, sweepAngle degrees, color]
      [-20.0, 110.0, 0xFF4285F4], // Blue (right)
      [90.0,  100.0, 0xFFEA4335], // Red  (bottom)
      [190.0, 85.0,  0xFFFBBC05], // Yellow (left-bottom)
      [275.0, 75.0,  0xFF34A853], // Green (left-top)
    ];

    const toRad = 3.14159265 / 180.0;
    final rect = Rect.fromLTWH(
      sw * 0.05, sh * 0.05, sw * 0.90, sh * 0.90,
    );
    final strokeW = sw * 0.18;

    for (final seg in segments) {
      canvas.drawArc(
        rect,
        seg[0] * toRad,
        seg[1] * toRad,
        false,
        Paint()
          ..color = Color(seg[2].toInt() | 0xFF000000)
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // White horizontal bar for the middle cutout of 'G'
    canvas.drawRect(
      Rect.fromLTWH(sw * 0.48, sh * 0.38, sw * 0.50, sh * 0.24),
      Paint()..color = const Color(0xFF1C1C1E),
    );

    // Blue fill for the horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(sw * 0.50, sh * 0.42, sw * 0.47, sh * 0.16),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}