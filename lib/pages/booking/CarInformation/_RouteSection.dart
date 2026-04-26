import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '_SummaryCard.dart';

class RouteSection extends StatelessWidget {
  final int pax;
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final double? distanceKm;
  final int? durationMin;

  const RouteSection({
    super.key,
    required this.pax,
    this.pickupAddress,
    this.dropoffAddress,
    this.scheduledDate,
    this.scheduledTime,
    this.distanceKm,
    this.durationMin,
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
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${dayNames[combined.weekday - 1]}, ${combined.day} ${monthNames[combined.month - 1]} ${combined.year} • ${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}';
      }
      return 'Now';
    }

    String formatDistance() {
      if (distanceKm != null) {
        return '${distanceKm!.toStringAsFixed(0)} KM';
      }
      return '-- KM';
    }

    String formatDuration() {
      if (durationMin != null) {
        if (durationMin! >= 60) {
          final hours = durationMin! ~/ 60;
          final mins = durationMin! % 60;
          if (mins > 0) {
            return '${hours}h ${mins}m';
          }
          return '${hours}h';
        }
        return '${durationMin}m';
      }
      return '-- m';
    }

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('route_details'),
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 16),

          // ── Date & time ──────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.send_outlined,
                color: AppColors.primaryPurple,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                formatDateTime(),
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Route stops with continuous line ─────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left column: circles and connecting line
                SizedBox(
                  width: 14,
                  child: Column(
                    children: [
                      // Origin circle (filled)
                      _DotFilled(),
                      // Vertical line that stretches to fill available space
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: const Color(0xFFCCCCCC),
                        ),
                      ),
                      // Destination circle (outlined)
                      _DotOutline(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right column: address text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupAddress ?? 'Pickup location',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        dropoffAddress ?? 'Drop-off location',
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

          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 14),

          // ── Stats row ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.straighten_outlined,
                  label: t.translate('stat_distance').toUpperCase(),
                  value: formatDistance(),
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.access_time_outlined,
                  label: t.translate('stat_eta').toUpperCase(),
                  value: formatDuration(),
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.person_outline_rounded,
                  label: t.translate('stat_passenger').toUpperCase(),
                  value: '$pax',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DotFilled extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: AppColors.primaryPurple,
      shape: BoxShape.circle,
    ),
  );
}

class _DotOutline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.subtext(context), width: 2),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: AppColors.primaryPurple),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontSize: 10,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
