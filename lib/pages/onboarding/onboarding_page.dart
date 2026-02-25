import 'package:flutter/material.dart';
import 'onboarding_step_1.dart';
import 'onboarding_step_2.dart';
import 'onboarding_step_3.dart';
import '../auth/login_page.dart';

/// Single AnimationController drives the car across all 3 steps:
///   Step 1 → carT animates 0.0 → 0.0   (car sits at origin, no trail)
///   Step 2 → carT animates 0.0 → 0.35  (car drives to midpoint)
///   Step 3 → carT animates 0.35 → 1.0  (car completes journey to destination)
///
/// When the user taps Next/Get Started, we animate to the next step's target.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _carController;
  late Animation<double> _carAnim;

  int _currentIndex = 0;

  // Target carT values per step
  static const _stepTargets = [0.0, 0.35, 1.0];

  @override
  void initState() {
    super.initState();
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Start at step 1 — car at origin, no movement yet
    _carAnim = AlwaysStoppedAnimation(0.0);
  }

  void _nextPage() {
    if (_currentIndex < 2) {
      final nextIndex = _currentIndex + 1;
      final fromT = _stepTargets[_currentIndex];
      final toT = _stepTargets[nextIndex];

      // Re-tween from current position → next step's target
      _carAnim = Tween<double>(begin: fromT, end: toT).animate(
        CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
      );
      _carController.duration = nextIndex == 2
          ? const Duration(milliseconds: 2200)
          : const Duration(milliseconds: 1800);
      _carController.forward(from: 0.0);

      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = nextIndex);
    } else {
      // Step 3 "Get Started" → navigate to Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B000F),
      body: AnimatedBuilder(
        animation: _carAnim,
        builder: (context, _) {
          final carT = _carAnim.value;
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              OnboardingStep1(onNext: _nextPage, carT: carT),
              OnboardingStep2(onNext: _nextPage, carT: carT),
              OnboardingStep3(onNext: _nextPage, carT: carT),
            ],
          );
        },
      ),
    );
  }
}