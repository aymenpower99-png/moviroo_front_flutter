import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../theme/app_colors.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../routing/router.dart';
import '../../../../core/utils/address_utils.dart';
import '_BookingConfirmedHeader.dart';
import '_BookingConfirmedCard.dart';
import '_BookingConfirmedButtons.dart';

class BookingConfirmedPage extends StatefulWidget {
  final String? bookingId;

  const BookingConfirmedPage({super.key, this.bookingId});

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage> {
  final BookingApiService _bookingApi = BookingApiService();
  Map<String, dynamic>? _bookingData;
  bool _isCancelling = false;
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _loadBookingData();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
        _maybeStartPolling(data);
        _maybeShowNoDriverModal(data);
      }
    } catch (e) {
      debugPrint('Failed to load booking data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Start polling when the ride is in a transitional state.
  void _maybeStartPolling(Map<String, dynamic>? data) {
    final status = data?['status'] as String?;
    // Poll while: PENDING (waiting for payment) or SEARCHING_DRIVER (waiting for assignment)
    if (status == 'PENDING' || status == 'SEARCHING_DRIVER') {
      _startPolling();
    }
  }

  /// Show no-driver modal if the system cancelled the ride.
  void _maybeShowNoDriverModal(Map<String, dynamic>? data) {
    final status = data?['status'] as String?;
    final cancelledBy = data?['cancelledBy'] as String?;
    final wasCard =
        (data?['paymentMethod'] as String?)?.toUpperCase() == 'CARD';

    if (status == 'CANCELLED' && cancelledBy == 'SYSTEM') {
      _showNoDriverDialog(wasCard);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || widget.bookingId == null) {
        _pollTimer?.cancel();
        return;
      }
      final data = await _bookingApi.getRideDetails(widget.bookingId!);
      if (!mounted) return;
      final status = data?['status'] as String?;
      final cancelledBy = data?['cancelledBy'] as String?;
      final wasCard =
          (data?['paymentMethod'] as String?)?.toUpperCase() == 'CARD';

      if (status == 'CANCELLED' && cancelledBy == 'SYSTEM') {
        _pollTimer?.cancel();
        setState(() => _bookingData = data);
        _showNoDriverDialog(wasCard);
        return;
      }

      if (status != null && status != 'PENDING' && status != 'SEARCHING_DRIVER') {
        _pollTimer?.cancel();
        setState(() => _bookingData = data);
      }
    });
  }

  void _showNoDriverDialog(bool wasCard) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryPurple),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No Drivers Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          wasCard
              ? 'We could not find a driver for your booking. Your booking has been cancelled and your refund is being processed to your card within 5–10 business days.'
              : 'We could not find a driver for your booking. Your booking has been cancelled.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.trajet,
                (route) => false,
              );
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Backend-first data accessors ─────────────────────────────────────────
  bool get _isPendingCard {
    final status = _bookingData?['status'] as String?;
    final method = (_bookingData?['paymentMethod'] as String?)?.toUpperCase();
    return status == 'PENDING' && method == 'CARD';
  }

  String? get _pickupAddress => _bookingData?['pickupAddress'] as String?;
  String? get _dropoffAddress => _bookingData?['dropoffAddress'] as String?;

  TimeOfDay? get _scheduledTime {
    final raw = _bookingData?['scheduledAt'] as String?;
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null)
        return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }
    return null;
  }

  int? get _durationMin {
    final v = _bookingData?['durationMin'];
    if (v is num) return v.toInt();
    return null;
  }

  String? get _paymentMethod => _bookingData?['paymentMethod'] as String?;

  String _formatEta() {
    if (_scheduledTime != null) {
      return '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';
    }
    final duration = _durationMin ?? 0;
    final now = DateTime.now().add(Duration(minutes: duration));
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatDistance() {
    final distance = _bookingData?['distanceKm'] ?? 0;
    return '${distance.toStringAsFixed(0)} KM';
  }

  int? get _passengerCount {
    final v = _bookingData?['passengerCount'];
    if (v is num) return v.toInt();
    return null;
  }

  int? get _seatCount {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    final v = cls?['seats'];
    if (v is num) return v.toInt();
    return null;
  }

  String _formatPassengers() {
    final count = _passengerCount ?? 1;
    return '$count ${count == 1 ? 'passenger riding' : 'passengers riding'}';
  }

  String _formatSeatCapacity() {
    final count = _seatCount;
    if (count != null) return '$count seats capacity';
    return '--';
  }

  void _handlePayNow() {
    if (widget.bookingId == null) return;
    _pollTimer?.cancel();
    Navigator.of(context).pushReplacementNamed(
      AppRouter.payment,
      arguments: {'bookingId': widget.bookingId},
    );
  }

  Future<void> _handleCancel() async {
    if (widget.bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking ID not found')));
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await _bookingApi.cancelRide(widget.bookingId!);
      if (mounted) {
        _pollTimer?.cancel();
        context.read<BookingProvider>().onBookingCancelled();

        // Reload booking data to get updated cancelledBy and paymentStatus
        await _loadBookingData();

        final paymentStatus = _bookingData?['paymentStatus'] as String?;
        final cancelledBy = _bookingData?['cancelledBy'] as String?;
        final wasCard =
            (_bookingData?['paymentMethod'] as String?)?.toUpperCase() ==
            'CARD';

        // Only show refund message if:
        // 1. Payment was actually charged (PAID), OR
        // 2. System cancelled (no driver found)
        final showRefundMessage =
            (paymentStatus == 'PAID') || (cancelledBy == 'SYSTEM');

        if (wasCard && showRefundMessage) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Booking Cancelled'),
              content: const Text(
                'Your booking has been cancelled. If a payment was charged, '
                'a full refund will be processed to your card within 5–10 business days.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isCash = _paymentMethod?.toLowerCase() == 'cash';
    final isPendingCard = _isPendingCard;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Column(
                  children: [
                    // ── Header ─────────────────────────────
                    BookingConfirmedHeader(
                      isCash: isCash,
                      isPendingCard: isPendingCard,
                    ),

                    // ── Main Card ─────────────────────────────
                    BookingConfirmedCard(
                      pickupAddress: _pickupAddress != null ? simplifyAddress(_pickupAddress!) : 'Pickup location',
                      dropoffAddress: _dropoffAddress != null ? simplifyAddress(_dropoffAddress!) : 'Dropoff location',
                      eta: _formatEta(),
                      distance: _formatDistance(),
                      passengers: _formatPassengers(),
                      seatCapacity: _formatSeatCapacity(),
                      isCash: isCash,
                    ),
                  ],
                ),
              ),
            ),

            // ── Buttons ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BookingConfirmedButtons(
                isCancelling: _isCancelling,
                isPendingCard: isPendingCard,
                onCancel: _handleCancel,
                onPayNow: isPendingCard ? _handlePayNow : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
