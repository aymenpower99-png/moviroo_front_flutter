import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'trajet_models.dart';
import 'ride_route_column.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
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
            // ── Header row ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _vehicleIcon(ride.vehicleIcon),
                    color: AppColors.primaryPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.vehicleType,
                        style: AppTextStyles.bodyLarge(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ride.date} • ${ride.vehicleName}',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${ride.price.toStringAsFixed(2)}',
                  style: AppTextStyles.priceMedium(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            RideRouteColumn(ride: ride),
            const SizedBox(height: 16),
            _ActionButton(ride: ride),
          ],
        ),
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'economy': return Icons.electric_bolt_rounded;
      default:        return Icons.directions_car_rounded;
    }
  }
}

// ── Action button per status ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final RideModel ride;
  const _ActionButton({required this.ride});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    switch (ride.status) {
      case RideStatus.upcoming:
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.near_me_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(t('track_ride'),
                          style: AppTextStyles.buttonPrimary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Icon(Icons.more_horiz_rounded,
                    color: AppColors.subtext(context), size: 22),
              ),
            ),
          ],
        );

      case RideStatus.completed:
        return GestureDetector(
          onTap: () {},
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                t('book_again'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
        );

      case RideStatus.cancelled:
        return Container(
          height: 46,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              t('cancelled'),
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}