import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'trajet_models.dart';

class RideTabBar extends StatelessWidget {
  final RideTab selected;
  final ValueChanged<RideTab> onTap;

  const RideTabBar({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: RideTab.values.map((tab) {
          final isSelected = tab == selected;
          final label = tab.name[0].toUpperCase() + tab.name.substring(1);
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: isSelected
                        ? AppTextStyles.tabLabelActive.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                          )
                        : AppTextStyles.tabLabel(context)
                            .copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}