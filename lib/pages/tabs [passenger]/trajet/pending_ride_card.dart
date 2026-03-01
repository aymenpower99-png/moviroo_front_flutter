import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'trajet_models.dart';
import 'ride_route_column.dart';

class PendingRideCard extends StatelessWidget {
  final RideModel ride;
  const PendingRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

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
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.electric_bolt_rounded,
                      color: AppColors.primaryPurple, size: 22),
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

            GestureDetector(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppColors.primaryPurple, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      t('pending_payment'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
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