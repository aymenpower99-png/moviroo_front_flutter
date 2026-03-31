import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PassHeaderCard extends StatelessWidget {
  final int userPoints;
  final int nextLevel;
  final int pointsToNext;
  final int currentLevelNumber;

  const PassHeaderCard({
    super.key,
    required this.userPoints,
    required this.nextLevel,
    required this.pointsToNext,
    this.currentLevelNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final progress = (userPoints / nextLevel).clamp(0.0, 1.0);
    final t        = AppLocalizations.of(context).translate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User badge row ──────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('pass_tier_name'),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // ✅ "Level 1" pill — replaces "Member" badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level $currentLevelNumber',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA855F7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ✅ No label above progress bar — just the bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF222228)
                  : const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFA855F7)),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Small hint below bar: X pts to next level
          Text(
            '$pointsToNext ${t('pass_pts_to_next')}',
            style: AppTextStyles.bodySmall(context),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}