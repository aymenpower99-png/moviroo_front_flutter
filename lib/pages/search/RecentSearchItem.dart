import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class RecentSearchItem {
  final String title;
  final String subtitle;
  final IconData categoryIcon;

  const RecentSearchItem({
    required this.title,
    required this.subtitle,
    required this.categoryIcon,
  });
}

class RecentSearchTile extends StatelessWidget {
  final RecentSearchItem item;
  final VoidCallback? onTap;

  const RecentSearchTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.categoryIcon,
                size: 22,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}
