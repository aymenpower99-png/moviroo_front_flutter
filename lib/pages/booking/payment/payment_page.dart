import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../services/stripe/stripe_service.dart';
import '../../../../services/membership/membership_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../services/currency/currency_service.dart';
import '_PaymentSummaryCard.dart';

class PaymentPage extends StatefulWidget {
  final String? bookingId;
  final double? lockedPrice;
  final double? discountPercent;

  const PaymentPage({
    super.key,
    this.bookingId,
    this.lockedPrice,
    this.discountPercent,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  final BookingApiService _bookingApi = BookingApiService();
  Map<String, dynamic>? _bookingData;
  bool _isLoadingBooking = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _loadBookingData();
    }
  }

  Future<void> _loadBookingData() async {
    if (widget.bookingId == null) return;
    setState(() => _isLoadingBooking = true);
    try {
      final data = await _bookingApi.getRideDetails(widget.bookingId!);
      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoadingBooking = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load booking data: $e');
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  /// Back button on Payment Page must go to the Booking List page,
  /// not back to the Booking Summary. Clear the stack and push trajet.
  void _goBack() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.trajet, (route) => false);
  }

  // ── Price accessor — prefer client-locked price for display consistency ──
  double get _displayPrice {
    // Use the locked price passed from booking summary (vehicle selection price).
    // Fall back to backend price only if locked price wasn't provided.
    if (widget.lockedPrice != null && widget.lockedPrice! > 0) {
      final discount =
          widget.discountPercent ?? _discountPercentFromBackend ?? 0;
      if (discount > 0) {
        return double.parse(
          (widget.lockedPrice! * (1 - discount / 100)).toStringAsFixed(2),
        );
      }
      return widget.lockedPrice!;
    }
    return _backendPrice;
  }

  double get _backendPrice {
    final pf = _bookingData?['priceFinal'];
    if (pf is num) return pf.toDouble();
    final pe = _bookingData?['priceEstimate'];
    if (pe is num) return pe.toDouble();
    return 0.0;
  }

  double? get _discountPercentFromBackend {
    final dp = _bookingData?['discountPercent'];
    if (dp is num && dp > 0) return dp.toDouble();
    return null;
  }

  double? get _discountPercent {
    if (widget.discountPercent != null && widget.discountPercent! > 0) {
      return widget.discountPercent;
    }
    return _discountPercentFromBackend;
  }

  String? get _vehicleClassName {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    return cls?['name'] as String?;
  }

  void _onPay() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No booking ID found')));
      return;
    }

    if (_displayPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Price not loaded yet')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Confirm ride with CARD method → creates TripPayment(PENDING) row.
      //    409 = already confirmed — safe to ignore and proceed.
      await _bookingApi.confirmRide(bookingId, paymentMethod: 'CARD');

      // 2. Get/create Stripe PaymentIntent for this ride's TripPayment row.
      final intentData = await _bookingApi.createStripeIntentForRide(bookingId);
      final clientSecret = intentData['clientSecret'] as String?;
      if (clientSecret == null) throw Exception('No client secret received');

      // 3. Present Stripe PaymentSheet — charges the card.
      //    Throws StripeException on cancel/failure.
      await StripeService.presentPaymentSheet(
        clientSecret,
        customerId: intentData['customerId'] as String?,
        ephemeralKey: intentData['ephemeralKey'] as String?,
      );

      // 4. Mark coupon used now that payment succeeded.
      final couponCode = _bookingData?['couponCode'] as String?;
      if (couponCode != null && couponCode.isNotEmpty) {
        try {
          await MembershipService.useCoupon(couponCode);
        } catch (_) {}
      }

      if (!mounted) return;
      context.read<BookingProvider>().onPaymentCompleted();
      setState(() => _isProcessing = false);

      // 5. Navigate to booking confirmed (awaiting driver assignment).
      //    The booking_confirmed page polls and updates UI when driver is assigned.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.bookingConfirmed,
        (route) => false,
        arguments: {'bookingId': bookingId},
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final msg = e.error.localizedMessage ?? 'Payment cancelled';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t        = AppLocalizations.of(context);
    final currency = context.watch<CurrencyService>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: AppColors.text(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.translate('payment'),
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.bookingId != null
                                ? '${t.translate('booking')} #${widget.bookingId!.substring(0, 8).toUpperCase()}'
                                : t.translate('booking'),
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.subtext(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ─────────────────────────────
                Expanded(
                  child: _isLoadingBooking
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            children: [
                              PaymentSummaryCard(
                                subtotal: _displayPrice,
                                rideLabel: _vehicleClassName,
                                discountPercent: _discountPercent,
                              ),
                              const SizedBox(height: 16),

                              // ── Stripe payment notice ──────────────────
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryPurple
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.credit_card_rounded,
                                            color: AppColors.primaryPurple,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Secure Card Payment',
                                              style:
                                                  AppTextStyles.bodyMedium(
                                                    context,
                                                  ).copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              'Powered by Stripe',
                                              style:
                                                  AppTextStyles.bodySmall(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.subtext(
                                                      context,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Tap "Pay" to enter your card details securely. '
                                      'Your card information is never stored on our servers.',
                                      style: AppTextStyles.bodySmall(context)
                                          .copyWith(
                                            color: AppColors.subtext(context),
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Security note ──────────────────────────
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: AppColors.subtext(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.translate('secured_encryption'),
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                          color: AppColors.subtext(context),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),

                // ── Pay button ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _onPay,
                      icon: const Icon(Icons.credit_card_outlined, size: 20),
                      label: Text(
                        _displayPrice > 0
                            ? '${t.translate('pay_amount')} ${currency.format(_displayPrice)}'
                            : t.translate('pay_amount'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: AppColors.primaryPurple.withValues(
                          alpha: 0.45,
                        ),
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
          // ── Processing overlay ─────────────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Processing Payment...',
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please do not close the app',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.subtext(context)),
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
