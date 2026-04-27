import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class CancelDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        t.translate('cancel_booking_title'),
        style: AppTextStyles.bodyLarge(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
      content: Text(
        t.translate('cancel_booking_message'),
        style: AppTextStyles.bodyMedium(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.translate('no'),
            style: TextStyle(color: AppColors.subtext(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(t.translate('yes_cancel')),
        ),
      ],
    );
  }
}
