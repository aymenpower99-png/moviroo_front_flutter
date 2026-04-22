import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Level
// ─────────────────────────────────────────────────────────────────────────────

enum PasswordStrength { none, weak, medium, strong }

PasswordStrength evaluateStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;

  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]').hasMatch(password)) score++;

  if (score <= 1) return PasswordStrength.weak;
  if (score <= 2) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

// ─────────────────────────────────────────────────────────────────────────────
// Strength Bar
// ─────────────────────────────────────────────────────────────────────────────

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = evaluateStrength(password);
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final (label, color, segments) = switch (strength) {
      PasswordStrength.weak => ('Weak', AppColors.error, 1),
      PasswordStrength.medium => ('Medium', const Color(0xFFF59E0B), 2),
      PasswordStrength.strong => ('Strong', const Color(0xFF22C55E), 3),
      PasswordStrength.none => ('', Colors.transparent, 0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < segments
                      ? color
                      : AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Requirements Checklist
// ─────────────────────────────────────────────────────────────────────────────

class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const PasswordRequirementsChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final rules = [
      (password.length >= 8, 'At least 8 characters'),
      (RegExp(r'[A-Z]').hasMatch(password), 'One uppercase letter'),
      (RegExp(r'[0-9]').hasMatch(password), 'One number'),
      (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]').hasMatch(password), 'One special character'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ...rules.map((rule) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                rule.$1 ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: rule.$1
                    ? const Color(0xFF22C55E)
                    : AppColors.subtext(context),
              ),
              const SizedBox(width: 8),
              Text(
                rule.$2,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: rule.$1
                      ? AppColors.text(context)
                      : AppColors.subtext(context),
                  fontWeight: rule.$1 ? FontWeight.w500 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
