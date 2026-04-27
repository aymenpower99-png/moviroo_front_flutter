import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class RouteRows extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;

  const RouteRows({required this.pickupAddress, required this.dropoffAddress});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Vertical route indicator ─────────────────────
          Column(
            children: [
              // Pickup circle (OUTLINED at TOP)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.subtext(context).withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              // Vertical line
              Expanded(
                child: Container(width: 2, color: const Color(0xFFE0E0E0)),
              ),
              // Dropoff circle (FILLED at BOTTOM)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Location text ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pickup
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Drop-off
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop-off',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffAddress,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
