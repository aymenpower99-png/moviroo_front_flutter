import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../routing/router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../services/download/download_service.dart';
import '../../../../services/driver_profile_cache.dart';
import '_AppBar.dart';
import '_ActionButtons.dart';
import '_CancelDialog.dart';
import '_BookingCard.dart';
import '_VehicleCard.dart';
import '_PassengerCard.dart';
import '_RideDetailsCard.dart';
import '_PriceSummaryCard.dart';
import '../RideDetails/DriverCard.dart';

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

  // Static cache to avoid reloading data
  static final Map<String, Map<String, dynamic>> _cache = {};

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _loadBookingData();
    }
  }

  Future<void> _loadBookingData() async {
    if (widget.bookingId == null) return;

    // Check cache first
    final cached = _cache[widget.bookingId];
    if (cached != null) {
      setState(() {
        _bookingData = cached;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _bookingApi.getRideDetails(widget.bookingId!);
      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoading = false;
        });
        // Cache the data if not null
        if (data != null) {
          _cache[widget.bookingId!] = data;
          // Pre-populate driver cache so avatars are instant everywhere
          final driver = data['driver'] as Map<String, dynamic>?;
          if (driver != null) {
            DriverProfileCache.instance.preloadDriverProfile(driver);
          }
        }
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

  int? get _passengerCount {
    final v = _bookingData?['passengerCount'];
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

  String? get _driverName {
    final d = _bookingData?['driver'] as Map<String, dynamic>?;
    if (d != null) {
      final first = d['firstName'] as String? ?? '';
      final last = d['lastName'] as String? ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
    }
    return null;
  }

  String? get _driverPhone {
    final d = _bookingData?['driver'] as Map<String, dynamic>?;
    return d?['phone'] as String?;
  }

  String? get _driverId {
    final d = _bookingData?['driver'] as Map<String, dynamic>?;
    return d?['id'] as String? ?? d?['userId'] as String?;
  }

  String? get _driverPhoto {
    final d = _bookingData?['driver'] as Map<String, dynamic>?;
    final fromData =
        d?['photo'] as String? ??
        d?['logoUrl'] as String? ??
        d?['logo_url'] as String?;
    if (fromData != null && fromData.isNotEmpty) return fromData;
    // Fallback to cache so avatar is instant even while loading
    final id = _driverId;
    if (id != null) {
      final cached = DriverProfileCache.instance.getLogoUrl(id);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    return null;
  }

  String? get _vehiclePlate {
    final v = _bookingData?['vehicle'] as Map<String, dynamic>?;
    return v?['plateNumber'] as String?;
  }

  double? get _driverRating {
    final v = _bookingData?['driverRating'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get _passengerRating {
    final v = _bookingData?['passengerRating'];
    if (v is num) return v.toDouble();
    return null;
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

  int? get _membershipPoints {
    final v = _bookingData?['loyaltyPointsEarned'];
    if (v is num) return v.toInt();
    return null;
  }

  double? get _discountPercent {
    final v = _bookingData?['discountPercent'];
    if (v is num && v > 0) return v.toDouble();
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

        if (wasCard && showRefundMessage && mounted) {
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
                    Navigator.of(context).pop(true);
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
          Navigator.pop(context, true);
        }
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

  Future<void> _downloadReceipt() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;

    setState(() => _isCancelling = true);
    try {
      // Get receipt URL with auth token
      final url = await _bookingApi.getReceiptDownloadUrl(bookingId);
      final token = await TokenStorage.getAccess();

      final fileName =
          'moviroo-receipt-${bookingId.substring(0, 8).toUpperCase()}.pdf';

      // Use Android DownloadManager via platform channel
      final authHeader = token != null ? 'Bearer $token' : null;
      await DownloadService.downloadFile(
        url: url,
        fileName: fileName,
        authHeader: authHeader,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt downloading to Downloads'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download receipt: $e')));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
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
                            passengers: _passengerCount,
                          ),
                          const SizedBox(height: 12),
                          VehicleCard(
                            imageUrl: _vehicleImageUrl,
                            name: _vehicleName,
                            seats: _seats,
                            bags: _bags,
                          ),
                          const SizedBox(height: 12),
                          if (_driverName != null)
                            DriverCard(
                              driverName: _driverName,
                              driverPhone: _driverPhone,
                              driverPhoto: _driverPhoto,
                              vehiclePlate: _vehiclePlate,
                              rating: _driverRating,
                            ),
                          if (_driverName != null) const SizedBox(height: 12),
                          PassengerCard(
                            passengerName: _passengerName,
                            email: _passengerEmail,
                            phone: _passengerPhone,
                            rating: _passengerRating,
                          ),
                          const SizedBox(height: 12),
                          PriceSummaryCard(
                            priceTnd: _priceTnd,
                            exactPrice: _exactPrice,
                            surgeMultiplier: _surgeMultiplier,
                            membershipPoints: _membershipPoints,
                            discountPercent: _discountPercent,
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
                                args: {
                                  'bookingId': bId,
                                  if (_discountPercent != null)
                                    'discountPercent': _discountPercent,
                                },
                              );
                            },
                            onCancel: () => _showCancelDialog(context),
                            onDownloadReceipt: _downloadReceipt,
                          ),
                          const SizedBox(height: 12),
                          _NeedHelpButton(),
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

// ── Need Help button ─────────────────────────────────────────────────────────

class _NeedHelpButton extends StatelessWidget {
  const _NeedHelpButton();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => AppRouter.push(context, AppRouter.support),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('need_help'),
                    style: AppTextStyles.settingsItem(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.translate('need_help_subtitle'),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.subtext(context)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.subtext(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
