import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  isDark ? 'images/logob.png' : 'images/lsnn.png',
                  width: 65,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Moviroo',
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}