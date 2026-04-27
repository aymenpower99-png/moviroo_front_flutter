import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '_SuccessIcon.dart';
import '_ReceiptCard.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String? bookingId;

  const PaymentSuccessPage({super.key, this.bookingId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final BookingApiService _bookingApi = BookingApiService();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Notify provider that a booking was confirmed
    Future.microtask(() {
      context.read<BookingProvider>().onBookingConfirmed();
    });

    if (widget.bookingId != null) {
      _loadBookingData();
    }
  }

  Future<void> _loadBookingData() async {
    if (widget.bookingId == null) return;
    try {
      final data = await _bookingApi.getRideDetails(widget.bookingId!);
      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load booking data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount() {
    final price = _bookingData?['priceFinal'];
    if (price is num) {
      return '${price.toStringAsFixed(2)} TND';
    }
    return '-- TND';
  }

  String _formatRefNumber() {
    if (widget.bookingId != null) {
      final shortRef = widget.bookingId!.substring(0, 8).toUpperCase();
      return '#$shortRef';
    }
    return '#TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}';
  }

  String _formatDate() {
    final raw = _bookingData?['scheduledAt'] as String?;
    if (raw != null) {
      final date = DateTime.tryParse(raw);
      if (date != null) {
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
    }
    final date = DateTime.now();
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
    final raw = _bookingData?['scheduledAt'] as String?;
    if (raw != null) {
      final date = DateTime.tryParse(raw);
      if (date != null) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
    }
    final time = TimeOfDay.now();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
