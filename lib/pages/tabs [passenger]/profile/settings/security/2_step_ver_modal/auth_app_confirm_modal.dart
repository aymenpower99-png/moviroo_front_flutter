import 'package:flutter/material.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../../l10n/app_localizations.dart';


/// Confirmation modal shown before removing the linked authentication app.
///
/// Returns `true` if the user confirms removal, `false` (or null) otherwise.
///
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => const AuthAppConfirmModal(),
/// ) ?? false;
/// ```
class AuthAppConfirmModal extends StatelessWidget {
  const AuthAppConfirmModal({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.phonelink_erase_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),

            const SizedBox(height: 16),

            // ── Title ──
            Text(
              t('Remove Authentication App?'),
              style: AppTextStyles.pageTitle(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // ── Body ──
            Text(
              t('This will remove your authentication app. You may lose access to 2-step verification.'),
              style: AppTextStyles.bodySmall(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // ── Actions ──
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.iconBg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('Cancel'),
                        style: AppTextStyles.bodyLarge(context),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Remove
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('Remove'),
                        style: AppTextStyles.bodyLarge(context)
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}