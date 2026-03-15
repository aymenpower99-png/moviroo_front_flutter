import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VEHICLE CLASS',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            )),
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
                child: Image.asset('images/bmw.png',
                    width: 75, height: 52, fit: BoxFit.contain),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Standard',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    // agency line removed
                    Text('Mercedes E Class, BMW 5 or similar',
                        style: AppTextStyles.bodySmall(context)),
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