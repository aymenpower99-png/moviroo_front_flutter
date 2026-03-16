import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_BookingCard.dart';
import '_VehicleCard.dart';
import '_PassengerCard.dart';
import '_RideDetailsCard.dart';
import '_PriceSummaryCard.dart';

class RideDetailsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const RideDetailsPage({super.key, this.onBack});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel booking?',
            style: AppTextStyles.bodyLarge(context)
                .copyWith(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel this booking?',
            style: AppTextStyles.bodyMedium(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No',
                style: TextStyle(color: AppColors.subtext(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [

            // ── App bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack ?? () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/booking');
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
                      'Ride details',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  // Balance the back button width
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BookingCard(),
                    const SizedBox(height: 12),
                    const RideDetailsCard(),
                    const SizedBox(height: 12),
                    const VehicleCard(),
                    const SizedBox(height: 12),
                    const PassengerCard(),
                    const SizedBox(height: 12),
                    const PriceSummaryCard(),
                    const SizedBox(height: 16),

                    // ── Payment button ─────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => AppRouter.clearAndGo(
                            context, AppRouter.payment),
                        icon: Icon(Icons.credit_card_outlined,
                            size: 20, color: AppColors.primaryPurple),
                        label: Text(
                          'Payment',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.primaryPurple),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface(context),
                          foregroundColor: AppColors.primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Cancel button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton.icon(
                        onPressed: () => _showCancelDialog(context),
                        icon: Icon(Icons.close_rounded,
                            color: Colors.red.shade400, size: 18),
                        label: Text(
                          'Cancel Booking',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.red.withOpacity(0.25)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}