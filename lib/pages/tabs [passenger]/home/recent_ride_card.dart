import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import 'home_models.dart';

class RecentRideCard extends StatelessWidget {
  final RecentRideModel r;
  const RecentRideCard({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        if (r.id != null) {
          AppRouter.push(context, AppRouter.rideDetails, args: {'bookingId': r.id});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            // ── Icon ─────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(
                Icons.history_rounded,
                color: AppColors.primaryPurple,
                size: 20,
                semanticLabel: t.translate('recent_ride_title'),
              ),
            ),

            const SizedBox(width: 14),

            // ── Name & Address ────────────────────────────────────
            // r.name and r.address are data-driven — translate them
            // at the API/model layer if needed.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(r.address, style: AppTextStyles.bodySmall(context)),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time & Arrow ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(r.time, style: AppTextStyles.dateTime(context)),
                const SizedBox(height: 6),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primaryPurple,
                    size: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}