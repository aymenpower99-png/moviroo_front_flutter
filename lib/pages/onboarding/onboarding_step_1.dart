import 'package:flutter/material.dart';
import 'package:moviroo/pages/onboarding/OnboardingShell.dart';

class OnboardingStep1 extends StatelessWidget {
  final VoidCallback onNext;
  final double carT;
  final double wheelAngle;

  const OnboardingStep1({
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
    currentStep: 0,
    label: 'SMART WAY TO TRAVEL',
    titleLine1: 'Book Your',
    titleAccent: 'Ride',
    subtitle:
        'Find nearby drivers instantly and book a comfortable ride in seconds.',
  );
}
