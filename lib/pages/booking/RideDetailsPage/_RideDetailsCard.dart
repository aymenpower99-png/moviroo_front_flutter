import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class RideDetailsCard extends StatelessWidget {
  final double? distanceKm;
  final int? durationMin;
  final int? passengers;

  const RideDetailsCard({
    super.key,
    this.distanceKm,
    this.durationMin,
    this.passengers,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    String formatDistance() {
      if (distanceKm != null) {
        return '${distanceKm!.toStringAsFixed(1)} km';
      }
      return '-- km';
    }

    String formatDuration() {
      if (durationMin != null) {
        if (durationMin! >= 60) {
          final hours = durationMin! ~/ 60;
          final mins = durationMin! % 60;
          if (mins > 0) {
            return '~${hours}h ${mins}min';
          }
          return '~${hours}h';
        }
        return '~$durationMin min';
      }
      return '-- min';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('ride_details'),
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.subtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.straighten_outlined,
                label: t.translate('distance'),
                value: formatDistance(),
              ),
              Divider(height: 24, color: AppColors.border(context)),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: t.translate('duration'),
                value: formatDuration(),
              ),
              Divider(height: 24, color: AppColors.border(context)),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: t.translate('passengers'),
                value: passengers?.toString() ?? '--',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.subtext(context)),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.text(context),
          ),
        ),
      ],
    );
  }
}
