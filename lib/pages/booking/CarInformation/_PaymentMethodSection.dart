import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '_SummaryCard.dart';

class PaymentMethodSection extends StatefulWidget {
  final String? initialMethod;
  final ValueChanged<String>? onPaymentMethodChanged;

  const PaymentMethodSection({
    super.key,
    this.initialMethod,
    this.onPaymentMethodChanged,
  });

  @override
  State<PaymentMethodSection> createState() => _PaymentMethodSectionState();
}

class _PaymentMethodSectionState extends State<PaymentMethodSection> {
  late String _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod ?? 'card';
  }

  void _onMethodChanged(String method) {
    setState(() {
      _selectedMethod = method;
    });
    widget.onPaymentMethodChanged?.call(method);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                color: AppColors.primaryPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('payment_method'),
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PaymentOption(
            icon: Icons.credit_card_outlined,
            label: t.translate('card'),
            subtitle: t.translate('card_subtitle'),
            isSelected: _selectedMethod == 'card',
            onTap: () => _onMethodChanged('card'),
          ),
          const SizedBox(height: 10),
          _PaymentOption(
            icon: Icons.attach_money_outlined,
            label: t.translate('cash'),
            subtitle: t.translate('cash_subtitle'),
            isSelected: _selectedMethod == 'cash',
            onTap: () => _onMethodChanged('cash'),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryPurple
                    : AppColors.surface(context),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.border(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 22, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.subtext(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
