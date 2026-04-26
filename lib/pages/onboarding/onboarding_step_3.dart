import 'package:flutter/material.dart';
import 'package:moviroo/pages/onboarding/OnboardingShell.dart';

class OnboardingStep3 extends StatelessWidget {
  final VoidCallback onNext;
  final double carT;
  final double wheelAngle;

  const OnboardingStep3({
    super.key,
    required this.onNext,
    required this.carT,
    this.wheelAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) => OnboardingShell(
    onNext: onNext,
    carT: carT,
    wheelAngle: wheelAngle,
    currentStep: 2,
    label: 'ARRIVE IN STYLE',
    titleLine1: 'You\'ve',
    titleAccent: 'Arrived',
    subtitle:
        'Safe, comfortable and on time. Rate your ride and go again whenever you\'re ready.',
    buttonLabel: 'Get Started',
  );
}
