import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';

InputDecoration buildFieldDecoration(
  BuildContext context, {
  required String hint,
  required IconData prefixIcon,
  bool readOnly = false,
  Widget? prefix,
  FocusNode? focusNode,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isFocused = focusNode?.hasFocus ?? false;

  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium(context)
        .copyWith(color: AppColors.subtext(context)),
    prefixIcon: prefix ??
        Icon(
          prefixIcon,
          color:
              isFocused ? AppColors.primaryPurple : AppColors.text(context),
          size: 20,
        ),
    filled: true,
    fillColor: readOnly
        ? (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F4))
        : AppColors.surface(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.primaryPurple,
        width: 1.5,
      ),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}