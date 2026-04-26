import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../services/stripe/stripe_service.dart';
import '_PaymentSummaryCard.dart';
import '_SavedCardSection.dart';
import '_NewCardForm.dart';

class PaymentPage extends StatefulWidget {
  final VehicleClassPrice? selectedVehicle;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const PaymentPage({
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
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // No saved cards yet → always show NewCardForm by default.
  // Toggle this to true once we wire up real saved cards from the backend.
  static const bool _hasSavedCard = false;
  bool _useNewCard = true;
  bool _isProcessing = false;
  final BookingApiService _bookingApi = BookingApiService();

  final _savedCardKey = GlobalKey<SavedCardSectionState>();
  final _newCardKey = GlobalKey<NewCardFormState>();

  /// Back button on Payment Page must go to the Booking List page,
  /// not back to the Booking Summary. Clear the stack and push trajet.
  void _goBack() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.trajet, (route) => false);
  }

  void _onPay() async {
    bool valid = false;
    if (_hasSavedCard && !_useNewCard) {
      valid = _savedCardKey.currentState?.validate() ?? false;
    } else {
      valid = _newCardKey.currentState?.validate() ?? false;
    }
    if (!valid) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Create ride (PENDING) on the backend
      final ride = await _bookingApi.createRide(
        pickupLat: widget.pickupLat ?? 0.0,
        pickupLon: widget.pickupLon ?? 0.0,
        dropoffLat: widget.dropoffLat ?? 0.0,
        dropoffLon: widget.dropoffLon ?? 0.0,
        pickupAddress: widget.pickupAddress,
        dropoffAddress: widget.dropoffAddress,
        classId: widget.selectedVehicle?.id,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
      );

      final rideId = ride?['id'] as String?;
      if (rideId == null) {
        throw Exception('Ride id not returned by backend');
      }

      // Step 2: Read card details from the form
      final cardState = _newCardKey.currentState;
      final cardNumber = cardState?.cardNumber ?? '';
      final cvv = cardState?.cvv ?? '';
      final cardholder = cardState?.cardholderName;
      final expiryParts = (cardState?.expiry ?? '/').split('/');
      final expiryMonth = expiryParts.isNotEmpty ? expiryParts[0] : '';
      final expiryYear = expiryParts.length > 1 ? expiryParts[1] : '';

      // Step 3: Process card payment via Stripe (test mode → simulated success)
      final price = widget.selectedVehicle?.exactPrice ?? 0.0;
      // TND uses millimes (1 TND = 1000 millimes) for Stripe
      final amountInMillimes = (price * 1000).toInt();

      final paymentSuccess = await StripeService.processCardPayment(
        amount: amountInMillimes,
        currency: 'tnd',
        bookingId: rideId,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
        cardholderName: cardholder,
      );

      if (!mounted) return;

      if (paymentSuccess) {
        // Step 3: Confirm ride on backend (locks price + triggers dispatch)
        await _bookingApi.confirmRide(rideId);

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        // Navigate to Payment Success and clear stack so back doesn't go to PaymentPage
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.paymentSuccess,
          (route) => false,
          arguments: {
            'selectedVehicle': widget.selectedVehicle,
            'pickupAddress': widget.pickupAddress,
            'dropoffAddress': widget.dropoffAddress,
            'pickupLat': widget.pickupLat,
            'pickupLon': widget.pickupLon,
            'dropoffLat': widget.dropoffLat,
            'dropoffLon': widget.dropoffLon,
            'scheduledDate': widget.scheduledDate,
            'scheduledTime': widget.scheduledTime,
            'bookingId': rideId,
          },
        );
      } else {
        // Payment failed — ride stays in PENDING, user can retry from Booking List
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                            t.translate('booking_ref'),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      children: [
                        PaymentSummaryCard(
                          subtotal: widget.selectedVehicle?.exactPrice ?? 0.0,
                          rideLabel: widget.selectedVehicle?.name,
                        ),
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
                              _useNewCard = false;
                            }),
                          ),
                        ],

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
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.subtext(context)),
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
                        t.translate('pay_amount'),
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
