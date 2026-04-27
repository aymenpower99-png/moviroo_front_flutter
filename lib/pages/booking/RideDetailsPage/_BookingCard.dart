import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class BookingCard extends StatelessWidget {
  final String? bookingId;
  final String? status;
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const BookingCard({
    super.key,
    this.bookingId,
    this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.scheduledDate,
    this.scheduledTime,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    String formatDateTime() {
      if (scheduledDate != null && scheduledTime != null) {
        final combined = DateTime(
          scheduledDate!.year,
          scheduledDate!.month,
          scheduledDate!.day,
          scheduledTime!.hour,
          scheduledTime!.minute,
        );
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${monthNames[combined.month - 1]} ${combined.day}, ${combined.year}, ${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}';
      }
      return 'Now';
    }

    final displayId = bookingId != null
        ? '#${bookingId!.substring(0, 8).toUpperCase()}'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Booking number + status ──────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('booking'),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.subtext(context)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      displayId,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (bookingId == null) return;
                        Clipboard.setData(ClipboardData(text: bookingId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.translate('booking_id_copied')),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy_outlined,
                        size: 16,
                        color: AppColors.subtext(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _StatusBadge(status: status),
          ],
        ),

        const SizedBox(height: 14),

        // ── Route card ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 6),
                  Text(
                    formatDateTime(),
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _RouteStop(
                dot: _DotFilledPurple(),
                label: 'Pick-up',
                title: pickupAddress ?? '--',
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 1.5,
                  height: 28,
                  color: AppColors.primaryPurple.withValues(alpha: 0.4),
                ),
              ),
              _RouteStop(
                dot: _DotOutlinePurple(),
                label: 'Drop-off',
                title: dropoffAddress ?? '--',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteStop extends StatelessWidget {
  final Widget dot;
  final String label;
  final String title;
  const _RouteStop({
    required this.dot,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: dot),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.subtext(context),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _DotFilledPurple extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      color: AppColors.primaryPurple,
      shape: BoxShape.circle,
    ),
  );
}

class _DotOutlinePurple extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.primaryPurple, width: 2),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'PENDING':
        bgColor = const Color(0xFFFF6B00).withValues(alpha: 0.15);
        textColor = const Color(0xFFFF6B00);
        icon = Icons.access_time_rounded;
        label = t.translate('payment_pending');
        break;
      case 'SCHEDULED':
      case 'SEARCHING_DRIVER':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.schedule_rounded;
        label = t.translate('scheduled');
        break;
      case 'ASSIGNED':
      case 'EN_ROUTE_TO_PICKUP':
      case 'ARRIVED':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        icon = Icons.local_taxi_rounded;
        label = t.translate('driver_assigned');
        break;
      case 'IN_TRIP':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        icon = Icons.navigation_rounded;
        label = t.translate('in_trip');
        break;
      case 'COMPLETED':
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey.shade700;
        icon = Icons.check_circle_outline;
        label = t.translate('completed');
        break;
      case 'CANCELLED':
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        label = t.translate('cancelled');
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey.shade600;
        icon = Icons.info_outline;
        label = '--';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
