import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/currency/currency_service.dart';

class PriceSummaryCard extends StatelessWidget {
  final int? priceTnd;
  final double? exactPrice;
  final double? surgeMultiplier;
  final int? membershipPoints;
  final double? discountPercent;

  const PriceSummaryCard({
    super.key,
    this.priceTnd,
    this.exactPrice,
    this.surgeMultiplier,
    this.membershipPoints,
    this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currency = context.watch<CurrencyService>();
    final hasDiscount = discountPercent != null && discountPercent! > 0;

    double? discountedPrice;
    if (priceTnd != null) discountedPrice = priceTnd!.toDouble();
    if (exactPrice != null) discountedPrice = exactPrice;

    double? originalPrice;
    if (hasDiscount && discountedPrice != null) {
      originalPrice = discountedPrice / (1 - discountPercent! / 100);
    }

    String formatPrice(double? v) {
      if (v != null) return currency.format(v);
      if (priceTnd != null) return currency.format(priceTnd!.toDouble());
      return currency.formatOrDash();
    }

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

          if (hasDiscount && originalPrice != null) ...[
            // Strikethrough original price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.translate('price'),
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.subtext(context)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(originalPrice),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      formatPrice(discountedPrice),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Discount badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${discountPercent!.toStringAsFixed(0)}% OFF',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.translate('coupon_applied'),
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                    ),
                  ],
                ),
                Text(
                  '-${formatPrice(originalPrice! - discountedPrice!)}',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ],
            ),
          ] else ...[
            _PriceRow(
              label: t.translate('price'),
              value: formatPrice(discountedPrice),
            ),
          ],
          const SizedBox(height: 10),

          if (membershipPoints != null && membershipPoints! > 0) ...[
            _PriceRow(
              label: t.translate('membership_points'),
              value: '$membershipPoints ${t.translate('pts')}',
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
                formatPrice(discountedPrice),
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
