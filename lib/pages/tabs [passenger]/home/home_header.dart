import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'home_search_bar.dart';

class HomeHeader extends StatelessWidget {
  final bool showSearch;
  const HomeHeader({super.key, required this.showSearch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(
          bottom: BorderSide(
            color: showSearch ? AppColors.border(context) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
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
          ),
          if (showSearch)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: HomeSearchBar(),
            ),
        ],
      ),
    );
  }
}