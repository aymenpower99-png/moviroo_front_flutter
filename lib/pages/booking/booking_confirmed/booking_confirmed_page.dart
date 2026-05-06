import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../theme/app_colors.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../routing/router.dart';
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
        // For card rides in PENDING state, poll until status changes
        final status = data?['status'] as String?;
        final method = (data?['paymentMethod'] as String?)?.toUpperCase();
        if (status == 'PENDING' && method == 'CARD') {
          _startPolling();
        }
      }
    } catch (e) {
      debugPrint('Failed to load booking data: $e');
      if (mounted) setState(() => _isLoading = false);
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
      if (status != null && status != 'PENDING') {
        _pollTimer?.cancel();
        setState(() => _bookingData = data);
      }
    });
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

  String _formatPax() {
    final cls = _bookingData?['vehicleClass'] as Map<String, dynamic>?;
    final seats = cls?['seats'];
    if (seats is num) {
      final seatCount = seats.toInt();
      return '$seatCount ${seatCount == 1 ? "ADULT" : "ADULTS"}';
    }
    return '2 ADULTS';
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

        final wasCard =
            (_bookingData?['paymentMethod'] as String?)?.toUpperCase() ==
                'CARD';
        if (wasCard) {
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

    final isCash       = _paymentMethod?.toLowerCase() == 'cash';
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
                      pickupAddress: _pickupAddress ?? 'Pickup location',
                      dropoffAddress: _dropoffAddress ?? 'Dropoff location',
                      eta: _formatEta(),
                      distance: _formatDistance(),
                      pax: _formatPax(),
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
