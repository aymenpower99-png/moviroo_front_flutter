import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

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
              padding: const EdgeInsets.only(top: 10),
              child: Image.asset(
                isDark
                    ? 'images/logo/moviroo dark_light_big.png'
                    : 'images/logo/moviroo light_dark_big.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
