import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class BookingConfirmedHeader extends StatelessWidget {
  final bool isCash;
  final bool isPendingCard;

  const BookingConfirmedHeader({
    required this.isCash,
    this.isPendingCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final Color circleColor = isPendingCard
        ? const Color(0xFFFF6B00)
        : AppColors.primaryPurple;
    final IconData circleIcon = isPendingCard
        ? Icons.payment_rounded
        : Icons.local_taxi_rounded;
    final String title = isPendingCard
        ? 'Complete Your Payment'
        : t.translate('booking_confirmed');
    final String subtitle = isPendingCard
        ? 'Your ride is confirmed. Tap "Pay Now" to complete payment and get your driver assigned.'
        : isCash
            ? 'Your driver is being assigned. You will pay in cash upon arrival.'
            : 'Your driver is being assigned. Your card has been charged.';

    return Column(
      children: [
        // ── 1. Confirmation header icon ───────────
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: circleColor.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(circleIcon, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),

        // ── Title ───────────────────────────────────
        Text(
          title,
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        const SizedBox(height: 10),

        // ── Subtitle ───────────────────────────────
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.subtext(context), height: 1.5),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
