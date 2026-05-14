import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../core/storage/token_storage.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../services/currency/currency_service.dart';
import '_SuccessIcon.dart';
import '_ReceiptCard.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String? bookingId;
  final String paymentMethod;

  const PaymentSuccessPage({
    super.key,
    this.bookingId,
    this.paymentMethod = 'card',
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final BookingApiService _bookingApi = BookingApiService();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;
  bool _isDownloading = false;

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

  String _formatAmount(CurrencyService currency) {
    final price = _bookingData?['priceFinal'];
    if (price is num) return currency.format(price.toDouble());
    return currency.formatOrDash();
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

  Future<void> _downloadReceipt() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;

    setState(() => _isDownloading = true);
    try {
      final url = await _bookingApi.getReceiptDownloadUrl(bookingId);
      final token = await TokenStorage.getAccess();

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'moviroo-receipt-${bookingId.substring(0, 8).toUpperCase()}.pdf';
      final savePath = '${tempDir.path}/$fileName';

      await dio.download(
        url,
        savePath,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(savePath)],
        subject: 'Moviroo Ride Receipt',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _cancelRide() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;

    setState(() => _isDownloading = true);
    try {
      final success = await _bookingApi.cancelRide(bookingId);
      if (!mounted) return;
      if (success) {
        context.read<BookingProvider>().onBookingCancelled();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.trajet,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currency = context.watch<CurrencyService>();
    final isCash = widget.paymentMethod.toLowerCase() == 'cash';

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
                isCash ? 'Booking Confirmed' : t.translate('payment_successful'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 10),

              // ── Subtitle ───────────────────────────────────
              Text(
                isCash
                    ? 'Your ride has been booked successfully. A driver will be assigned shortly.'
                    : t.translate('payment_successful_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.subtext(context), height: 1.5),
              ),

              const Spacer(flex: 2),

              // ── Receipt card ───────────────────────────────
              ReceiptCard(
                amount: _formatAmount(currency),
                refNumber: _formatRefNumber(),
                date: _formatDate(),
                time: _formatTime(),
                paymentMethod: widget.paymentMethod,
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
                      borderRadius: BorderRadius.circular(18),
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

              // ── Secondary action button ────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: isCash
                    ? OutlinedButton(
                        onPressed: _isDownloading ? null : _cancelRide,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Text(
                                'Cancel Ride',
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                      )
                    : OutlinedButton(
                        onPressed: _isDownloading ? null : _downloadReceipt,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          side: BorderSide(
                            color: AppColors.primaryPurple,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryPurple,
                                ),
                              )
                            : Text(
                                t.translate('download_receipt'),
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primaryPurple,
                                ),
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
