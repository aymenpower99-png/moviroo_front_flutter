import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class PillChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool showChevron;
  final VoidCallback onTap;

  const PillChip({
    super.key,
    this.icon,
    required this.label,
    required this.showChevron,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.subtext(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
