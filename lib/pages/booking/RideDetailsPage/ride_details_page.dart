import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../providers/booking_provider.dart';
import '_AppBar.dart';
import '_ActionButtons.dart';
import '_CancelDialog.dart';
import '_BookingCard.dart';
import '_VehicleCard.dart';
import '_PassengerCard.dart';
import '_RideDetailsCard.dart';
import '_PriceSummaryCard.dart';

class RideDetailsPage extends StatefulWidget {
  final VoidCallback? onBack;
  final String? bookingId;

  const RideDetailsPage({super.key, this.onBack, this.bookingId});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final BookingApiService _bookingApi = BookingApiService();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _loadBookingData();
    }
  }

  Future<void> _loadBookingData() async {
    if (widget.bookingId == null) return;
    setState(() => _isLoading = true);
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

  // ── Backend-first data accessors ─────────────────────────────────────────
  String? get _pickupAddress => _bookingData?['pickupAddress'] as String?;
  String? get _dropoffAddress => _bookingData?['dropoffAddress'] as String?;

  DateTime? get _scheduledDate {
    final raw = _bookingData?['scheduledAt'] as String?;
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  TimeOfDay? get _scheduledTime {
    final raw = _bookingData?['scheduledAt'] as String?;
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null)
        return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }
    return null;
  }

  double? get _distanceKm {
    final v = _bookingData?['distanceKm'];
    if (v is num) return v.toDouble();
    return null;
  }

  int? get _durationMin {
    final v = _bookingData?['durationMin'];
    if (v is num) return v.toInt();
    return null;
  }

  int? get _seats {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    final v = cls?['seats'];
    if (v is num) return v.toInt();
    return null;
  }

  int? get _bags {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    final v = cls?['bags'];
    if (v is num) return v.toInt();
    return null;
  }

  String? get _vehicleName {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    return cls?['name'] as String?;
  }

  String? get _vehicleImageUrl {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    return cls?['imageUrl'] as String?;
  }

  String? get _passengerName {
    final p = _bookingData?['passenger'] as Map<String, dynamic>?;
    if (p != null) {
      final first = p['firstName'] as String? ?? '';
      final last = p['lastName'] as String? ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
    }
    return null;
  }

  String? get _passengerEmail {
    final p = _bookingData?['passenger'] as Map<String, dynamic>?;
    return p?['email'] as String?;
  }

  String? get _passengerPhone {
    final p = _bookingData?['passenger'] as Map<String, dynamic>?;
    return p?['phone'] as String?;
  }

  String? get _bookingStatus {
    return _bookingData?['status'] as String?;
  }

  int? get _priceTnd {
    final v = _bookingData?['priceFinal'];
    if (v is num) return v.toInt();
    return null;
  }

  double? get _exactPrice {
    final v = _bookingData?['priceFinal'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get _surgeMultiplier {
    final v = _bookingData?['surgeMultiplier'];
    if (v is num) return v.toDouble();
    return null;
  }

  int? get _loyaltyPoints {
    final v = _bookingData?['loyaltyPointsEarned'];
    if (v is num) return v.toInt();
    return null;
  }

  bool _isCancelling = false;

  Future<void> _cancelBooking() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;

    setState(() => _isCancelling = true);
    try {
      final success = await _bookingApi.cancelRide(bookingId);
      if (!mounted) return;
      setState(() => _isCancelling = false);

      if (success) {
        // Notify provider to refresh booking list
        context.read<BookingProvider>().onBookingCancelled();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel booking')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CancelDialog(onConfirm: _cancelBooking),
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
            RideDetailsAppBar(onBack: widget.onBack),

            // ── Scrollable content ─────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        16 + bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookingCard(
                            bookingId: widget.bookingId,
                            status: _bookingStatus,
                            pickupAddress: _pickupAddress,
                            dropoffAddress: _dropoffAddress,
                            scheduledDate: _scheduledDate,
                            scheduledTime: _scheduledTime,
                          ),
                          const SizedBox(height: 12),
                          RideDetailsCard(
                            distanceKm: _distanceKm,
                            durationMin: _durationMin,
                            passengers: _seats,
                          ),
                          const SizedBox(height: 12),
                          VehicleCard(
                            imageUrl: _vehicleImageUrl,
                            name: _vehicleName,
                            seats: _seats,
                            bags: _bags,
                          ),
                          const SizedBox(height: 12),
                          PassengerCard(
                            passengerName: _passengerName,
                            email: _passengerEmail,
                            phone: _passengerPhone,
                          ),
                          const SizedBox(height: 12),
                          PriceSummaryCard(
                            priceTnd: _priceTnd,
                            exactPrice: _exactPrice,
                            surgeMultiplier: _surgeMultiplier,
                            loyaltyPoints: _loyaltyPoints,
                          ),
                          const SizedBox(height: 16),

                          RideDetailsActionButtons(
                            bookingStatus: _bookingStatus,
                            isCancelling: _isCancelling,
                            onPay: () {
                              final bId = widget.bookingId;
                              if (bId == null) return;
                              AppRouter.push(
                                context,
                                AppRouter.payment,
                                args: {'bookingId': bId},
                              );
                            },
                            onCancel: () => _showCancelDialog(context),
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
