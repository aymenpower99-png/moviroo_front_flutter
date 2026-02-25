import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'trajet_models.dart';

/// Shared pickup → drop-off route indicator used by both
/// [RideCard] and [PendingRideCard].
class RideRouteColumn extends StatelessWidget {
  final RideModel ride;
  const RideRouteColumn({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple,
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppColors.border(context),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.primaryPurple,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup',
                  style: AppTextStyles.priceLabel(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.pickup,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Drop-off',
                  style: AppTextStyles.priceLabel(context).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.dropoff,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}