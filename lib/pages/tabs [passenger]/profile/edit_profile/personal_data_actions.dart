import 'package:flutter/material.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Save Button
// ─────────────────────────────────────────────────────────────────────────────

class SaveButton extends StatelessWidget {
  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onPressed;

  const SaveButton({
    super.key,
    required this.isSaving,
    required this.hasChanges,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return AnimatedOpacity(
      opacity: hasChanges ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (hasChanges && !isSaving) ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            disabledBackgroundColor: AppColors.primaryPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(t('save_changes'), style: AppTextStyles.buttonPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Danger Section
// ─────────────────────────────────────────────────────────────────────────────

class DangerSection extends StatelessWidget {
  const DangerSection({super.key});

  void _showDeleteDialog(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('delete_account'),
          style: AppTextStyles.bodyLarge(context)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t('delete_account_warning'),
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: AppColors.subtext(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('delete'), style: AppTextStyles.buttonSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDeleteDialog(context),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A0F0F)
              : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A1515)
                : const Color(0xFFFFDDDD),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A1010)
                    : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('delete_account'),
                    style: AppTextStyles.settingsItem(context)
                        .copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('delete_account_subtitle'),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: isDark
                          ? const Color(0xFF8B4444)
                          : const Color(0xFFB07070),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }
}