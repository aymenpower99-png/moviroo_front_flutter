import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';

class BookingConfirmedButtons extends StatelessWidget {
  final bool isCancelling;
  final VoidCallback onCancel;

  const BookingConfirmedButtons({
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      children: [
        // Check Booking button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => AppRouter.push(context, AppRouter.trajet),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 12,
              shadowColor: AppColors.primaryPurple.withValues(
                alpha: 0.45,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Check Booking',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Cancel Booking button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: isCancelling ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
              side: BorderSide(
                color: AppColors.primaryPurple,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isCancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPurple,
                      ),
                    ),
                  )
                : Text(
                    t.translate('cancel_booking'),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primaryPurple,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
