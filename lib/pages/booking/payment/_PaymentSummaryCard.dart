import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PaymentSummaryCard extends StatelessWidget {
  /// Base price of the ride in TND (before fees).
  final double subtotal;

  /// Fixed service fee in TND.
  final double serviceFee;

  /// Optional label override for the main line (e.g. vehicle class name).
  final String? rideLabel;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    this.serviceFee = 0.0,
    this.rideLabel,
  });

  String _fmt(double v) => '${v.toStringAsFixed(2)} TND';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          _PriceRow(
            label: rideLabel ?? t.translate('standard_transfer'),
            value: _fmt(subtotal),
          ),
          if (serviceFee > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: t.translate('service_fee'),
              value: _fmt(serviceFee),
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
                _fmt(total),
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
