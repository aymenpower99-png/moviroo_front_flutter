import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICE SUMMARY',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.subtext(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 11,
              )),
          const SizedBox(height: 14),

          _PriceRow(label: 'Base fare', value: '70.00 TND'),
          const SizedBox(height: 10),
          _PriceRow(label: 'Airport fee', value: '10.00 TND'),
          const SizedBox(height: 10),
          _PriceRow(label: 'Service fee', value: '5.00 TND'),

          const SizedBox(height: 12),
          Divider(color: AppColors.border(context)),
          const SizedBox(height: 12),

          Row(
            children: [
              Text('Total',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text('85.00 TND',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primaryPurple)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium(context)
                .copyWith(color: AppColors.subtext(context))),
        const Spacer(),
        Text(value,
            style: AppTextStyles.bodyMedium(context)
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}