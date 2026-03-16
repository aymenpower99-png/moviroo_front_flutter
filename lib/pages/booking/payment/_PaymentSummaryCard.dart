import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key});

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
          Text('SUMMARY',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.subtext(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 11,
              )),
          const SizedBox(height: 14),
          _PriceRow(label: 'Standard Transfer', value: '75.00 TND'),
          const SizedBox(height: 8),
          _PriceRow(label: 'Service fee', value: '10.00 TND'),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(fontWeight: FontWeight.w800)),
              Text('85.00 TND',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple,
                  )),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
        Text(value,
            style: AppTextStyles.bodyMedium(context)
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}