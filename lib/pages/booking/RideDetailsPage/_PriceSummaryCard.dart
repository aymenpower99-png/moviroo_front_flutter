import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PriceSummaryCard extends StatelessWidget {
  final int? priceTnd;
  final double? exactPrice;
  final double? surgeMultiplier;
  final int? loyaltyPoints;

  const PriceSummaryCard({
    super.key,
    this.priceTnd,
    this.exactPrice,
    this.surgeMultiplier,
    this.loyaltyPoints,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    String formatPrice() {
      if (priceTnd != null) {
        return '$priceTnd TND';
      } else if (exactPrice != null) {
        return '${exactPrice!.toStringAsFixed(2)} TND';
      }
      return '-- TND';
    }

    final displayPrice = formatPrice();

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
          Text(
            t.translate('price_summary'),
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          _PriceRow(label: t.translate('price'), value: displayPrice),
          const SizedBox(height: 10),

          if (loyaltyPoints != null && loyaltyPoints! > 0) ...[
            _PriceRow(
              label: t.translate('loyalty_points'),
              value: '+$loyaltyPoints pts',
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 12),
          Divider(color: AppColors.border(context)),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                t.translate('total'),
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              Text(
                displayPrice,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primaryPurple,
                ),
              ),
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
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.subtext(context)),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
