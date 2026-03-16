import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_BookingSummaryCard.dart';
import '_RouteSection.dart';
import '_DiscountSection.dart';
import '_BillingAddressSection.dart';
import '_PriceSummarySection.dart';

class BookingSummaryPage extends StatefulWidget {
  const BookingSummaryPage({super.key});

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  int _pax  = 2;
  int _bags = 3;

  final _billingKey = GlobalKey<BillingAddressSectionState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(
                            context, AppRouter.booking);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 17, color: AppColors.text(context)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Booking summary',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    BookingSummaryCard(
                      pax: _pax,
                      bags: _bags,
                      vehicleName: 'Economy',
                      carName: 'BMW 3 Series or similar',
                    ),
                    const SizedBox(height: 12),
                    RouteSection(pax: _pax),
                    const SizedBox(height: 12),
                    const DiscountSection(),
                    const SizedBox(height: 12),
                    BillingAddressSection(key: _billingKey),
                    const SizedBox(height: 12),
                    const PriceSummarySection(),
                  ],
                ),
              ),
            ),

            // ── Confirm button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final billingOk =
                        _billingKey.currentState?.validateAndProceed() ?? true;
                    if (!billingOk) return;
                    AppRouter.clearAndGo(context, AppRouter.rideDetails);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shadowColor:
                        AppColors.primaryPurple.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirm booking',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
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