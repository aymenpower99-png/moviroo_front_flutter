import 'package:flutter/material.dart';
import 'package:moviroo/routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';

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
    final t = AppLocalizations.of(context);

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
                    // ── 1. Confirmation header icon ───────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.30,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Title ───────────────────────────────────
                    Text(
                      t.translate('booking_confirmed'),
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 24),
                    ),
                    const SizedBox(height: 10),

                    // ── Subtitle ───────────────────────────────
                    Text(
                      isCash
                          ? 'Your driver is being assigned. You will pay in cash upon arrival.'
                          : 'Your driver is being assigned. Your card has been charged.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.subtext(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 2-4. Main Card (Route + Trip Info + Payment) ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Route section ─────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: _RouteRows(
                              pickupAddress:
                                  _pickupAddress ?? 'Pickup location',
                              dropoffAddress:
                                  _dropoffAddress ?? 'Dropoff location',
                            ),
                          ),

                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border(context),
                          ),

                          // ── 3. Trip info row (3 columns) ──────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatColumn(
                                      label: 'ETA',
                                      value: _formatEta(),
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: AppColors.border(context),
                                  ),
                                  Expanded(
                                    child: _StatColumn(
                                      label: 'DISTANCE',
                                      value: _formatDistance(),
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: AppColors.border(context),
                                  ),
                                  Expanded(
                                    child: _StatColumn(
                                      label: 'PAX',
                                      value: _formatPax(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border(context),
                          ),

                          // ── 4. Payment Method row ─────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Payment Method',
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.subtext(context)),
                                ),
                                const Spacer(),
                                Icon(
                                  isCash
                                      ? Icons.payments_outlined
                                      : Icons.credit_card_rounded,
                                  size: 18,
                                  color: AppColors.text(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCash ? 'Cash' : 'Card',
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 6. Buttons ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  // Check Booking button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          AppRouter.push(context, AppRouter.trajet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: AppColors.primaryPurple.withValues(
                          alpha: 0.45,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Check Booking',
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cancel Booking button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        side: BorderSide(
                          color: AppColors.primaryPurple,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryPurple,
                                ),
                              ),
                            )
                          : Text(
                              t.translate('cancel_booking'),
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRows extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;

  const _RouteRows({required this.pickupAddress, required this.dropoffAddress});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Vertical route indicator ─────────────────────
          Column(
            children: [
              // Pickup circle (OUTLINED at TOP)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.subtext(context).withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              // Vertical line
              Expanded(
                child: Container(width: 2, color: const Color(0xFFE0E0E0)),
              ),
              // Dropoff circle (FILLED at BOTTOM)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Location text ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pickup
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Drop-off
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop-off',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.subtext(context),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffAddress,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }
}
