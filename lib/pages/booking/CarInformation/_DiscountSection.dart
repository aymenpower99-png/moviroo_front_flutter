import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/membership/membership_service.dart';
import '_SummaryCard.dart';

class DiscountSection extends StatefulWidget {
  final void Function(double discountPercent, String code)? onDiscountApplied;

  const DiscountSection({super.key, this.onDiscountApplied});

  @override
  State<DiscountSection> createState() => _DiscountSectionState();
}

class _DiscountSectionState extends State<DiscountSection>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _applied = false;
  String? _error;
  String? _appliedCode;
  double _appliedPercent = 0;

  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut));
    _badgeFade = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await MembershipService.validateCoupon(code);
      if (!mounted) return;

      setState(() {
        _applied = true;
        _appliedCode = result.code;
        _appliedPercent = result.discountPercentage;
        _loading = false;
      });

      _badgeCtrl.forward(from: 0);
      widget.onDiscountApplied?.call(result.discountPercentage, result.code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _clear() {
    setState(() {
      _applied = false;
      _appliedCode = null;
      _appliedPercent = 0;
      _error = null;
      _controller.clear();
    });
    _badgeCtrl.reset();
    widget.onDiscountApplied?.call(0, '');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primaryPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('discount_code'),
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Input row (hidden when applied) ─────────────────
          if (!_applied)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.bodyMedium(context),
                    enabled: !_loading,
                    decoration: InputDecoration(
                      hintText: t.translate('enter_code'),
                      hintStyle: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryPurple,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _loading
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          t.translate('apply'),
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),

          // ── Error message ────────────────────────────────────
          if (_error != null && !_applied) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          // ── Success badge ────────────────────────────────────
          if (_applied)
            FadeTransition(
              opacity: _badgeFade,
              child: ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.18
                          : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coupon Applied! −${_appliedPercent.toStringAsFixed(0)}%',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Text(
                              _appliedCode ?? '',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.subtext(context),
                                fontSize: 11,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _clear,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.subtext(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
