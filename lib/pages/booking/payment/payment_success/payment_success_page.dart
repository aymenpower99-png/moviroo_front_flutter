import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '_SuccessIcon.dart';
import '_ReceiptCard.dart';

class PaymentSuccessPage extends StatelessWidget {
  final VehicleClassPrice? selectedVehicle;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final String? bookingId;

  const PaymentSuccessPage({
    super.key,
    this.selectedVehicle,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLon,
    this.dropoffLat,
    this.dropoffLon,
    this.scheduledDate,
    this.scheduledTime,
    this.bookingId,
  });

  String _formatAmount() {
    final price = selectedVehicle?.exactPrice ?? 0.0;
    return '${price.toStringAsFixed(2)} TND';
  }

  String _formatRefNumber() {
    if (bookingId != null) {
      return '#BK-$bookingId';
    }
    return '#TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}';
  }

  String _formatDate() {
    final date = scheduledDate ?? DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime() {
    final time = scheduledTime ?? TimeOfDay.now();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Success icon ───────────────────────────────
              const SuccessIcon(),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────
              Text(
                t.translate('payment_successful'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 10),

              // ── Subtitle ───────────────────────────────────
              Text(
                t.translate('payment_successful_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.subtext(context), height: 1.5),
              ),

              const Spacer(flex: 2),

              // ── Receipt card ───────────────────────────────
              ReceiptCard(
                amount: _formatAmount(),
                refNumber: _formatRefNumber(),
                date: _formatDate(),
                time: _formatTime(),
                cardBrand: 'Visa',
                cardLast4: '4242',
              ),

              const Spacer(flex: 3),

              // ── View Bookings button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => AppRouter.push(context, AppRouter.trajet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shadowColor: AppColors.primaryPurple.withValues(
                      alpha: 0.50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'View Bookings',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Download Receipt button ────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text(context),
                    side: BorderSide(
                      color: AppColors.border(context),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    t.translate('download_receipt'),
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
