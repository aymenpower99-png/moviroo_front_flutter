import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';
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
        // Notify provider to refresh booking list
        context.read<BookingProvider>().onBookingCancelled();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pop(context);
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
                    BookingConfirmedHeader(isCash: isCash),

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
                onCancel: _handleCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
