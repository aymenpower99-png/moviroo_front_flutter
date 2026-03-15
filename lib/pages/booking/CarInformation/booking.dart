import 'package:flutter/material.dart';
import 'package:moviroo/pages/booking/CarInformation/_TopBar.dart';
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
  // pax/bags still drive RouteSection's PASSENGER stat
  int _pax  = 2;
  int _bags = 3;

  // Key to call validateAndProceed() on the billing section before confirming
  final _billingKey = GlobalKey<BillingAddressSectionState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // ── Card 1: vehicle info ───────────────────
                    BookingSummaryCard(
                      pax: _pax,
                      bags: _bags,
                      vehicleName: 'Economy',
                      carName: 'BMW 3 Series or similar',
                    ),

                    const SizedBox(height: 12),

                    // ── Card 2: route details ──────────────────
                    RouteSection(pax: _pax),

                    const SizedBox(height: 12),

                    // ── Card 3: discount code ──────────────────
                    const DiscountSection(),

                    const SizedBox(height: 12),

                    // ── Card 4: billing address ────────────────
                    BillingAddressSection(key: _billingKey),

                    const SizedBox(height: 12),

                    // ── Card 5: price summary ──────────────────
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
                    // Validate billing address before proceeding
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