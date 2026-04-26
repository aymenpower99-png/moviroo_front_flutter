import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class BookingCard extends StatelessWidget {
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const BookingCard({
    super.key,
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

    final bookingId =
        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

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
                      bookingId,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: bookingId.replaceAll('#', '')),
                        );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.amber.shade600,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t.translate('payment_pending'),
                    style: TextStyle(
                      color: Colors.amber.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
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
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.subtext(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDateTime(),
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _RouteStop(
                dot: _DotFilled(),
                title: pickupAddress ?? 'Pickup location',
                subtitle: '',
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
                dot: _DotOutline(),
                title: dropoffAddress ?? 'Drop-off location',
                subtitle: '',
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
  final String title;
  final String subtitle;
  const _RouteStop({
    required this.dot,
    required this.title,
    required this.subtitle,
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
              title,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall(context)),
          ],
        ),
      ],
    );
  }
}

class _DotFilled extends StatelessWidget {
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

class _DotOutline extends StatelessWidget {
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
