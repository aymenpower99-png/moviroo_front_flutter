import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../../services/currency/currency_service.dart';
import 'trajet_models.dart';
import 'ride_route_column.dart';

class PendingRideCard extends StatelessWidget {
  final RideModel ride;
  const PendingRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final t        = AppLocalizations.of(context).translate;
    final currency = context.watch<CurrencyService>();
    final isCard   = ride.paymentMethod == 'CARD';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.vehicleType,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _IconLabel(
                            icon: Icons.calendar_today_rounded,
                            label: ride.date,
                          ),
                          const SizedBox(width: 12),
                          _IconLabel(
                            icon: Icons.access_time_rounded,
                            label: ride.time,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(ride.price),
                      style: AppTextStyles.priceMedium(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            RideRouteColumn(ride: ride),
            const SizedBox(height: 16),

            // ── Complete Payment — full width ──────────────────
            GestureDetector(
              onTap: () => AppRouter.push(
                context,
                isCard ? AppRouter.payment : AppRouter.rideDetails,
                args: {'bookingId': ride.rideId},
              ),
              child: Container(
                height: 46,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isCard
                      ? AppColors.primaryPurple.withValues(alpha: 0.10)
                      : const Color(0xFFFF6B00).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCard
                        ? AppColors.primaryPurple.withValues(alpha: 0.45)
                        : const Color(0xFFFF6B00).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCard
                          ? Icons.credit_card_rounded
                          : Icons.schedule_rounded,
                      color: isCard
                          ? AppColors.primaryPurple
                          : const Color(0xFFFF6B00),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCard ? t('pay_now') : t('Pending Payment'),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCard
                            ? AppColors.primaryPurple
                            : const Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small icon + label ────────────────────────────────────────────────────────

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.subtext(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
