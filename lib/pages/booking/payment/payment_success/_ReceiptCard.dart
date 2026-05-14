import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class ReceiptCard extends StatelessWidget {
  final String amount;
  final String refNumber;
  final String date;
  final String time;
  final String paymentMethod;

  const ReceiptCard({
    super.key,
    required this.amount,
    required this.refNumber,
    required this.date,
    required this.time,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isCash = paymentMethod.toLowerCase() == 'cash';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [

          // ── Total Amount ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Text(
                  t.translate('total_amount'),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.subtext(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border(context)),

          // ── Rows ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _ReceiptRow(
                  label: t.translate('receipt_ref_number'),
                  value: refNumber,
                ),
                const SizedBox(height: 14),
                _ReceiptRow(
                  label: t.translate('receipt_date'),
                  value: date,
                ),
                const SizedBox(height: 14),
                _ReceiptRow(
                  label: t.translate('receipt_time'),
                  value: time,
                ),
                const SizedBox(height: 14),
                _ReceiptRow(
                  label: t.translate('receipt_payment_method'),
                  valueWidget: isCash
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 20,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cash',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Card icon
                            Container(
                              width: 32, height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 6,
                                    child: Container(
                                      width: 14, height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEB001B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    child: Container(
                                      width: 14, height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF79E1B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Card',
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _ReceiptRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.subtext(context),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}