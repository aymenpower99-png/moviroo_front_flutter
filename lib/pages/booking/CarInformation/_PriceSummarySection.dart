import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '_SummaryCard.dart';

class PriceSummarySection extends StatefulWidget {
  final int? priceTnd;
  final double? exactPrice;
  final double? surgeMultiplier;
  final int? loyaltyPoints;
  final double? appliedDiscountPercent;

  const PriceSummarySection({
    super.key,
    this.priceTnd,
    this.exactPrice,
    this.surgeMultiplier,
    this.loyaltyPoints,
    this.appliedDiscountPercent,
  });

  @override
  State<PriceSummarySection> createState() => _PriceSummarySectionState();
}

class _PriceSummarySectionState extends State<PriceSummarySection>
    with SingleTickerProviderStateMixin {

  late AnimationController _animCtrl;
  late Animation<double>   _priceAnim;
  double _animFromPrice = 0;
  double _animToPrice   = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _priceAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animFromPrice = _rawPrice();
    _animToPrice   = _discountedPrice();
  }

  @override
  void didUpdateWidget(PriceSummarySection old) {
    super.didUpdateWidget(old);
    final newFrom = _rawPrice();
    final newTo   = _discountedPrice();
    if (newTo != _animToPrice || newFrom != _animFromPrice) {
      _animFromPrice = newFrom;
      _animToPrice   = newTo;
      _priceAnim = Tween<double>(begin: _animFromPrice, end: _animToPrice)
          .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  double _rawPrice() {
    if (widget.priceTnd != null) return widget.priceTnd!.toDouble();
    if (widget.exactPrice != null) return widget.exactPrice!;
    return 0;
  }

  double _discountedPrice() {
    final raw      = _rawPrice();
    final discount = widget.appliedDiscountPercent ?? 0;
    if (raw == 0 || discount == 0) return raw;
    return raw * (1 - discount / 100);
  }

  bool get _hasDiscount =>
      (widget.appliedDiscountPercent ?? 0) > 0 && _rawPrice() > 0;

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '${price.toInt()} TND';
    }
    return '${price.toStringAsFixed(2)} TND';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasSurge = widget.surgeMultiplier != null && widget.surgeMultiplier! > 1.0;
    final rawDisplay = _rawPrice() == 0 ? '-- TND' : _formatPrice(_rawPrice());

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                t.translate('price_summary'),
                style: AppTextStyles.bodySmall(context)
                    .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _PriceRow(label: t.translate('outbound_transfer'), value: rawDisplay),

          if (hasSurge) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: t.translate('surge_multiplier'),
              value: 'x${widget.surgeMultiplier!.toStringAsFixed(1)}',
            ),
          ],

          if (_hasDiscount) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Coupon discount',
              value: '−${widget.appliedDiscountPercent!.toStringAsFixed(0)}%',
              valueColor: AppColors.primaryPurple,
            ),
          ],

          if (widget.loyaltyPoints != null && widget.loyaltyPoints! > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: t.translate('moviroo_membership'),
              value: '+${widget.loyaltyPoints} pts',
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Total row (animated when discount applied) ────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.translate('total'),
                style: AppTextStyles.bodyLarge(context)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              if (_hasDiscount)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Strikethrough original price
                    Text(
                      rawDisplay,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        decoration: TextDecoration.lineThrough,
                        fontSize: 12,
                      ),
                    ),
                    // Animated discounted price
                    AnimatedBuilder(
                      animation: _priceAnim,
                      builder: (_, __) => Text(
                        _formatPrice(_priceAnim.value == 0
                            ? _discountedPrice()
                            : _priceAnim.value),
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  rawDisplay,
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(fontWeight: FontWeight.w800),
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
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
        Text(
          value,
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

