import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class VehicleCard extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final int? seats;
  final int? bags;

  const VehicleCard({
    super.key,
    this.imageUrl,
    this.name,
    this.seats,
    this.bags,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('vehicle_class'),
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: 75,
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 75,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.border(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: AppColors.subtext(context),
                          ),
                        ),
                      )
                    : Container(
                        width: 75,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.subtext(context),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Standard',
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    if (seats != null || bags != null)
                      Text(
                        '${seats != null ? '$seats seats' : ''}${seats != null && bags != null ? ' • ' : ''}${bags != null ? '$bags bags' : ''}',
                        style: AppTextStyles.bodySmall(context),
                      ),
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
