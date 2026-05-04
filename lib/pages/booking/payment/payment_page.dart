import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../services/stripe/stripe_service.dart';
import '../../../../services/membership/membership_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '_PaymentSummaryCard.dart';
import '_SavedCardSection.dart';
import '_NewCardForm.dart';

class PaymentPage extends StatefulWidget {
  final String? bookingId;
  final double? lockedPrice;
  final double? discountPercent;

  const PaymentPage({super.key, this.bookingId, this.lockedPrice, this.discountPercent});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _hasSavedCard = false;
  bool _useNewCard = true;
  bool _isProcessing = false;
  bool _saveCard = false;
  final BookingApiService _bookingApi = BookingApiService();
  List<Map<String, dynamic>> _savedCards = [];
  Map<String, dynamic>? _bookingData;
  bool _isLoadingBooking = false;

  final _savedCardKey = GlobalKey<SavedCardSectionState>();
  final _newCardKey = GlobalKey<NewCardFormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
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

  Future<void> _loadSavedCards() async {
    final hasCards = await StripeService.hasSavedCards();
    final cards = await StripeService.getSavedCards();
    if (mounted) {
      setState(() {
        _hasSavedCard = hasCards;
        _savedCards = cards;
        if (hasCards) {
          _useNewCard = false;
        }
      });
    }
  }

  Future<void> _onDeleteCard(String token) async {
    try {
      await StripeService.deleteCard(token);
      await _loadSavedCards();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Card removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove card: $e')));
      }
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
      final discount = widget.discountPercent ?? _discountPercentFromBackend ?? 0;
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
    bool valid = false;
    if (_hasSavedCard && !_useNewCard) {
      valid = _savedCardKey.currentState?.validate() ?? false;
    } else {
      valid = _newCardKey.currentState?.validate() ?? false;
      _saveCard = _newCardKey.currentState?.saveCard ?? false;
    }
    if (!valid) return;

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

    setState(() {
      _isProcessing = true;
    });

    try {
      // Read card details from the form
      final cardState = _newCardKey.currentState;
      final cardNumber = cardState?.cardNumber ?? '';
      final cvv = cardState?.cvv ?? '';
      final cardholder = cardState?.cardholderName;
      final expiryParts = (cardState?.expiry ?? '/').split('/');
      final expiryMonth = expiryParts.isNotEmpty ? expiryParts[0] : '';
      final expiryYear = expiryParts.length > 1 ? expiryParts[1] : '';

      // Use display price (locked from vehicle selection) — TND uses millimes (1 TND = 1000 millimes)
      final amountInMillimes = (_displayPrice * 1000).toInt();

      final paymentSuccess = await StripeService.processCardPayment(
        amount: amountInMillimes,
        currency: 'tnd',
        bookingId: bookingId,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
        cardholderName: cardholder,
      );

      if (!mounted) return;

      if (paymentSuccess) {
        if (_saveCard && _useNewCard) {
          try {
            await StripeService.saveCard(
              cardNumber: cardNumber,
              expiryMonth: expiryMonth,
              expiryYear: expiryYear,
              cardholderName: cardholder ?? '',
            );
          } catch (e) {
            debugPrint('Failed to save card: $e');
          }
        }

        // Confirm ride on backend (locks price + triggers dispatch) — card payment
        await _bookingApi.confirmRide(bookingId, paymentMethod: 'CARD');

        // Mark coupon as used now that payment + ride confirmation succeeded
        final couponCode = _bookingData?['couponCode'] as String?;
        if (couponCode != null && couponCode.isNotEmpty) {
          try {
            await MembershipService.useCoupon(couponCode);
          } catch (_) {
            // Non-blocking — don't fail if coupon mark fails
          }
        }

        // Notify provider that payment was completed
        if (mounted) {
          context.read<BookingProvider>().onPaymentCompleted();
        }

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        // Navigate to Payment Success — only pass bookingId
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.paymentSuccess,
          (route) => false,
          arguments: {'bookingId': bookingId},
        );
      } else {
        // Notify provider that payment failed
        if (mounted) {
          context.read<BookingProvider>().onPaymentFailed();
        }

        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Card declined')));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
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

                              if (_hasSavedCard && !_useNewCard) ...[
                                SavedCardSection(
                                  key: _savedCardKey,
                                  onUseNewCard: () =>
                                      setState(() => _useNewCard = true),
                                  savedCards: _savedCards,
                                  onDeleteCard: _onDeleteCard,
                                ),
                              ] else ...[
                                NewCardForm(
                                  key: _newCardKey,
                                  onBackToSaved: _hasSavedCard
                                      ? () =>
                                            setState(() => _useNewCard = false)
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
                            ? '${t.translate('pay_amount')} ${_displayPrice.toStringAsFixed(2)} TND'
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
