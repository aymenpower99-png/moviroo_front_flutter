import 'package:flutter/material.dart';
import 'package:moviroo/theme/app_colors.dart';

class Card extends StatelessWidget {
  final Widget child;
  const Card({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}
