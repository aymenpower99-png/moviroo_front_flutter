import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class TranslationBanner extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const TranslationBanner({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // Icône traduction
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.translate_rounded,
                color: AppColors.primaryPurple, size: 16),
          ),
          const SizedBox(width: 10),

          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-translating Arabic',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        size: 11,
                        color: AppColors.subtext(context)),
                    const SizedBox(width: 3),
                    Text(
                      'to English',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle ON/OFF
          GestureDetector(
            onTap: () => onToggle(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primaryPurple
                    : AppColors.border(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                enabled ? 'On' : 'Off',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
