import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/driver_avatar.dart';

class DriverCard extends StatelessWidget {
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehiclePlate;
  final double? rating;

  const DriverCard({
    super.key,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehiclePlate,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('driver').toUpperCase(),
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              // Driver photo
              Stack(
                children: [
                  DriverAvatar(
                    name: driverName ?? 'Driver',
                    photoUrl: driverPhoto,
                    size: 56,
                    shape: BoxShape.rectangle,
                    borderRadius: 14,
                    backgroundColor: AppColors.iconBg(context),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface(context),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName ?? t.translate('unknown_driver'),
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (rating != null)
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    if (vehiclePlate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehiclePlate!,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.subtext(context)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
