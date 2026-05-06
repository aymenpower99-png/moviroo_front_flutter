import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/currency/currency_service.dart';

class PaymentSummaryCard extends StatelessWidget {
  /// Base price of the ride in TND (already discounted if coupon applied).
  final double subtotal;

  /// Fixed service fee in TND.
  final double serviceFee;

  /// Optional label override for the main line (e.g. vehicle class name).
  final String? rideLabel;

  /// Discount percentage (0–100). Shows strikethrough original price when > 0.
  final double? discountPercent;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    this.serviceFee = 0.0,
    this.rideLabel,
    this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final t        = AppLocalizations.of(context);
    final currency = context.watch<CurrencyService>();
    String fmt(double v) => currency.format(v);
    final hasDiscount = discountPercent != null && discountPercent! > 0;
    final originalPrice = hasDiscount
        ? subtotal / (1 - discountPercent! / 100)
        : null;
    final total = subtotal + serviceFee;

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
            t.translate('payment_summary'),
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (hasDiscount) ...[
            // Ride row: strikethrough original → discounted
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rideLabel ?? t.translate('standard_transfer'),
                  style: AppTextStyles.bodyMedium(context),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt(originalPrice!),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      fmt(subtotal),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Discount badge row
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
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${fmt(originalPrice! - subtotal)}',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ] else ...[
            _PriceRow(
              label: rideLabel ?? t.translate('standard_transfer'),
              value: fmt(subtotal),
            ),
          ],
          if (serviceFee > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: t.translate('service_fee'),
              value: fmt(serviceFee),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.translate('total'),
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                fmt(total),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
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
