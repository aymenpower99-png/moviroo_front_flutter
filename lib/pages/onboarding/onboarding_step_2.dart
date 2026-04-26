import 'package:flutter/material.dart';
import 'package:moviroo/pages/onboarding/OnboardingShell.dart';

class OnboardingStep2 extends StatelessWidget {
  final VoidCallback onNext;
  final double carT;
  final double wheelAngle;

  const OnboardingStep2({
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
    currentStep: 1,
    label: 'REAL-TIME TRACKING',
    titleLine1: 'Track Your',
    titleAccent: 'Driver',
    subtitle:
        'Watch your driver arrive in real-time on a live map. Always know where they are.',
  );
}
