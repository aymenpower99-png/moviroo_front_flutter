import 'package:flutter/material.dart';
import '../../routing/router.dart';
import '../../../../l10n/app_localizations.dart';

class AppTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppTabBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  static const _routes = [
    AppRouter.home,
    AppRouter.driverHome,
    AppRouter.membre,
    AppRouter.support,
    AppRouter.profile,
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.card_membership_rounded,
    Icons.headset_mic_rounded,
    Icons.person_outline_rounded,
  ];

  static const _labelKeys = [
    'tab_home',
    'tab_bookings',
    'tab_membre',
    'tab_support',
    'tab_profile',
  ];

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    onTap?.call(index);
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF0F0F12) : Colors.white;
    final topBorder = isDark ? const Color(0xFF1E1E24) : const Color(0xFFE0E0E8);
    final t         = AppLocalizations.of(context).translate;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: topBorder, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(_icons.length, (i) {
          final selected        = i == currentIndex;
          final unselectedColor = isDark
              ? const Color(0xFF6B6B75)
              : const Color(0xFF9B9BAA);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleTap(context, i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width:  selected ? 48 : 28,
                    height: 32,
                    decoration: selected
                        ? BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(16),
                          )
                        : null,
                    child: Center(
                      child: Icon(
                        _icons[i],
                        size: 22,
                        color: selected ? Colors.white : unselectedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(_labelKeys[i]),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? (isDark ? Colors.white : const Color(0xFF0B0B0F))
                          : unselectedColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}