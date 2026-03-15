import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PickerChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Intrinsic size — chip is exactly as wide as its content
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // KEY: never expand
          children: [
            Icon(icon, size: 14, color: AppColors.primaryPurple),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }
}