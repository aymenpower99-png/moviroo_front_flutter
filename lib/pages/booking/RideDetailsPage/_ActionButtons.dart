import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class RideDetailsActionButtons extends StatelessWidget {
  final String? bookingStatus;
  final bool isCancelling;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  const RideDetailsActionButtons({
    super.key,
    required this.bookingStatus,
    required this.isCancelling,
    this.onPay,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final showPayButton = bookingStatus == 'PENDING' || bookingStatus == 'pendingPayment';
    final showCancelButton = bookingStatus == 'PENDING' ||
        bookingStatus == 'SCHEDULED' ||
        bookingStatus == 'SEARCHING_DRIVER';

    return Column(
      children: [
        if (showPayButton)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onPay,
              icon: Icon(
                Icons.credit_card_outlined,
                size: 20,
                color: AppColors.primaryPurple,
              ),
              label: Text(
                t.translate('payment'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primaryPurple,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface(context),
                foregroundColor: AppColors.primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border(context)),
                ),
              ),
            ),
          ),
        if (showPayButton) const SizedBox(height: 10),

        if (showCancelButton)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton.icon(
              onPressed: isCancelling ? null : onCancel,
              icon: Icon(
                Icons.close_rounded,
                color: Colors.red.shade400,
                size: 18,
              ),
              label: Text(
                t.translate('cancel_booking'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
