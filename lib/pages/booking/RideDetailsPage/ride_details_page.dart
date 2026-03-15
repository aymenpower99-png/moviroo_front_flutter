import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_BookingCard.dart';
import '_VehicleCard.dart';
import '_PassengerCard.dart';
import '_RideDetailsCard.dart';
import '_PriceSummaryCard.dart';

class RideDetailsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const RideDetailsPage({super.key, this.onBack});

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

            // ── App bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack ??
                        () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/booking');
                          }
                        },
                  ),
                  Expanded(
                    child: Text('Ride details',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable cards — takes all remaining space ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Fixed bottom — always visible, never scrolls ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                border: Border(
                  top: BorderSide(color: AppColors.border(context)),
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const PriceSummaryCard(),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          AppRouter.clearAndGo(context, AppRouter.payment),
                      icon: Icon(Icons.credit_card_outlined,
                          size: 20, color: AppColors.primaryPurple),
                      label: Text('Payment',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.primaryPurple)),
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

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: Icon(Icons.close_rounded,
                          color: Colors.red.shade400, size: 18),
                      label: Text('Cancel Booking',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
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

          ],
        ),
      ),
    );
  }
}