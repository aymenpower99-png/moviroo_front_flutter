import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '_BookingSummaryCard.dart';
import '_RouteSection.dart';
import '_DiscountSection.dart';
import '_BillingAddressSection.dart';
import '_PaymentMethodSection.dart';
import '_PriceSummarySection.dart';

class BookingSummaryPage extends StatefulWidget {
  final VehicleClassPrice? selectedVehicle;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const BookingSummaryPage({
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
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  final _billingKey = GlobalKey<BillingAddressSectionState>();
  String _selectedPaymentMethod = 'card';
  final BookingApiService _bookingApi = BookingApiService();
  bool _isProcessing = false;

  void _onPaymentMethodChanged(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _onConfirmBooking() async {
    final billingOk = _billingKey.currentState?.validateAndProceed() ?? true;
    if (!billingOk) return;

    if (!mounted) return;

    // Route based on payment method
    if (_selectedPaymentMethod == 'card') {
      // Card payment → Create booking (PENDING) first, then navigate to Payment Page
      setState(() {
        _isProcessing = true;
      });

      try {
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

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        // Navigate to Payment Page with bookingId only
        AppRouter.push(context, AppRouter.payment, args: {'bookingId': rideId});
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating booking: $e')));
        }
      }
    } else {
      // Cash payment → Create + Confirm ride, then go to Booking Confirmed
      setState(() {
        _isProcessing = true;
      });

      try {
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

        // Confirm ride (locks price + triggers dispatch)
        await _bookingApi.confirmRide(rideId);

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        // Navigate to Booking Confirmed Screen - only pass bookingId
        AppRouter.push(
          context,
          AppRouter.bookingConfirmed,
          args: {'bookingId': rideId},
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating ride: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                          context,
                          AppRouter.booking,
                        );
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
                  Expanded(
                    child: Text(
                      t.translate('booking_summary'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
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
                      pax: widget.selectedVehicle?.seats ?? 2,
                      bags: widget.selectedVehicle?.bags ?? 3,
                      vehicleName: widget.selectedVehicle?.name ?? 'Economy',
                      carName:
                          '${widget.selectedVehicle?.name ?? 'Economy'} or similar',
                      imageUrl: widget.selectedVehicle?.imageUrl,
                    ),
                    const SizedBox(height: 12),
                    RouteSection(
                      pax: widget.selectedVehicle?.seats ?? 2,
                      pickupAddress: widget.pickupAddress,
                      dropoffAddress: widget.dropoffAddress,
                      scheduledDate: widget.scheduledDate,
                      scheduledTime: widget.scheduledTime,
                      distanceKm: widget.selectedVehicle?.distanceKm,
                      durationMin: widget.selectedVehicle?.durationMin,
                    ),
                    const SizedBox(height: 12),
                    const DiscountSection(),
                    const SizedBox(height: 12),
                    BillingAddressSection(key: _billingKey),
                    const SizedBox(height: 12),
                    PaymentMethodSection(
                      initialMethod: _selectedPaymentMethod,
                      onPaymentMethodChanged: _onPaymentMethodChanged,
                    ),
                    const SizedBox(height: 12),
                    PriceSummarySection(
                      priceTnd: widget.selectedVehicle?.priceTnd,
                      exactPrice: widget.selectedVehicle?.exactPrice,
                      surgeMultiplier: widget.selectedVehicle?.surgeMultiplier,
                      loyaltyPoints: widget.selectedVehicle?.loyaltyPoints,
                    ),
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
                  onPressed: _isProcessing ? null : _onConfirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shadowColor: AppColors.primaryPurple.withValues(
                      alpha: 0.30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: AppColors.primaryPurple.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.translate('confirm_booking'),
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
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
