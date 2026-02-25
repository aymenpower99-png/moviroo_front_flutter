import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: AppColors.subtext(context), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Where to?',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.subtext(context),
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}