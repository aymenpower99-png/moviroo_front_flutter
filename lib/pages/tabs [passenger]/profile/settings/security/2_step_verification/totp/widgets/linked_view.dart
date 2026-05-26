import 'package:flutter/material.dart';
import '../../../../../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../../../../../theme/app_colors.dart';

class LinkedView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onUnlink;

  const LinkedView({
    super.key,
    required this.isLoading,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Column(
      children: [
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                t('Authentication App Linked'),
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.iconBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Authenticator App'),
                      style: AppTextStyles.bodyLarge(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('Active • Added Jun 2024'),
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        GestureDetector(
          onTap: isLoading ? null : onUnlink,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.error,
                    ),
                  )
                : Text(
                    t('Remove Authentication App'),
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: AppColors.error,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}