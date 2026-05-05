import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'help_center_models.dart';

// ── Single category card ──────────────────────────────────────────────────────

class HelpCategoryCard extends StatelessWidget {
  final HelpCategory category;
  final VoidCallback onTap;

  const HelpCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purple icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            // Category name
            Text(
              category.name,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Dynamic article count
            Text(
              t('articles_count').replaceAll(
                '{count}',
                category.articleCount.toString(),
              ),
              style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2-column grid of category cards ──────────────────────────────────────────

class HelpCenterGrid extends StatelessWidget {
  final List<HelpCategory> categories;
  final void Function(HelpCategory) onCategoryTap;

  const HelpCenterGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => HelpCategoryCard(
          category: categories[i],
          onTap: () => onCategoryTap(categories[i]),
        ),
      ),
    );
  }
}
