import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// Circular map floating button.
class MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MapBtn({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : Colors.white).withValues(
            alpha: 0.95,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: AppColors.text(context)),
        ),
      ),
    );
  }
}
