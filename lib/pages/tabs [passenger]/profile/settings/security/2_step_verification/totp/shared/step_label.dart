import 'package:flutter/material.dart';
import '../../../../../../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../../../../../../theme/app_colors.dart';

class StepLabel extends StatelessWidget {
  final String number;
  final String label;

  const StepLabel({super.key, required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            gradient: AppColors.purpleGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyLarge(context)),
      ],
    );
  }
}