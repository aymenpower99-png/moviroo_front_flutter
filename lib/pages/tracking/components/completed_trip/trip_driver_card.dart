import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

/// Driver info card for the trip-completed screen (no rating — see _RatingCard).
class TripDriverCard extends StatelessWidget {
  final String driverName;
  final String vehicleName;

  const TripDriverCard({
    super.key,
    required this.driverName,
    required this.vehicleName,
  });

  static const _purple = AppColors.primaryPurple;
  static const _gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iconBg(context),
              border: Border.all(
                color: _purple.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Icon(Icons.person_rounded, color: _purple, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        driverName.isNotEmpty ? driverName : 'Driver',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, color: _gold, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  vehicleName.isNotEmpty ? vehicleName : 'Vehicle',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.subtext(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
