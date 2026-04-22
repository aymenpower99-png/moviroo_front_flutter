import 'package:flutter/material.dart';
import 'onboarding_step_1.dart';
import 'onboarding_step_2.dart';
import 'onboarding_step_3.dart';
import '../auth/login/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  late AnimationController _carController;
  late Animation<double> _carAnim;
  late AnimationController _wheelController;

  int _currentIndex = 0;
  bool _isAnimating = false;

  static const _stepTargets = [0.0, 0.45, 1.0];

  @override
  void initState() {
    super.initState();

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // Start at position 0 — car sits at origin
    _carAnim = AlwaysStoppedAnimation(0.0);
  }

  Future<void> _nextPage() async {
    if (_isAnimating) return;

    if (_currentIndex < 2) {
      _isAnimating = true;

      final nextIndex = _currentIndex + 1;
      final fromT = _stepTargets[_currentIndex];
      final toT   = _stepTargets[nextIndex];

      // Build new tween from current car position → next target
      _carAnim = Tween<double>(begin: fromT, end: toT).animate(
        CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
      );

      _carController.duration = nextIndex == 2
          ? const Duration(milliseconds: 2200)
          : const Duration(milliseconds: 1800);

      // Slide the page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      setState(() => _currentIndex = nextIndex);

      // Drive the car — only ONE forward() call
      await _carController.forward(from: 0.0);
      _isAnimating = false;
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      body: AnimatedBuilder(
        animation: Listenable.merge([_carAnim, _wheelController]),
        builder: (context, _) {
          final carT       = _carAnim.value;
          final wheelAngle = _wheelController.value * 2 * 3.14159;
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              OnboardingStep1(onNext: _nextPage, carT: carT, wheelAngle: wheelAngle),
              OnboardingStep2(onNext: _nextPage, carT: carT, wheelAngle: wheelAngle),
              OnboardingStep3(onNext: _nextPage, carT: carT, wheelAngle: wheelAngle),
            ],
          );
        },
      ),
    );
  }
}