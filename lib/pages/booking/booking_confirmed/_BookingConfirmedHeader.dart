import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class BookingConfirmedHeader extends StatelessWidget {
  final bool isCash;

  const BookingConfirmedHeader({required this.isCash});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      children: [
        // ── 1. Confirmation header icon ───────────
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // ── Title ───────────────────────────────────
        Text(
          t.translate('booking_confirmed'),
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        const SizedBox(height: 10),

        // ── Subtitle ───────────────────────────────
        Text(
          isCash
              ? 'Your driver is being assigned. You will pay in cash upon arrival.'
              : 'Your driver is being assigned. Your card has been charged.',
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
