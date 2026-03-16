import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_PaymentSummaryCard.dart';
import '_SavedCardSection.dart';
import '_NewCardForm.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _hasSavedCard = true;
  bool _useNewCard = false;

  // GlobalKeys to access child state for validation
  final _savedCardKey = GlobalKey<SavedCardSectionState>();
  final _newCardKey = GlobalKey<NewCardFormState>();

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.booking);
    }
  }

  void _onPay() {
    bool valid = false;

    if (_hasSavedCard && !_useNewCard) {
      valid = _savedCardKey.currentState?.validate() ?? false;
    } else {
      valid = _newCardKey.currentState?.validate() ?? false;
    }

    if (!valid) return;

    AppRouter.push(context, AppRouter.paymentSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.text(context),
                      size: 20,
                    ),
                    onPressed: _goBack,
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Text('Booking #78438620',
                          style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.subtext(context))),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    const PaymentSummaryCard(),
                    const SizedBox(height: 16),

                    if (_hasSavedCard && !_useNewCard) ...[
                      SavedCardSection(
                        key: _savedCardKey,
                        onUseNewCard: () =>
                            setState(() => _useNewCard = true),
                      ),
                    ] else ...[
                      NewCardForm(
                        key: _newCardKey,
                        onBackToSaved: _hasSavedCard
                            ? () => setState(() => _useNewCard = false)
                            : null,
                        onSaved: () => setState(() {
                          _hasSavedCard = true;
                          _useNewCard = false;
                        }),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Security note ──────────────────────────
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 14, color: AppColors.subtext(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Secured with 256-bit encryption',
                          style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.subtext(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Pay button — always visible, never overflowed ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _onPay,
                  icon: const Icon(Icons.credit_card_outlined, size: 20),
                  label: const Text('Pay 85.00 TND',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shadowColor: AppColors.primaryPurple.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}