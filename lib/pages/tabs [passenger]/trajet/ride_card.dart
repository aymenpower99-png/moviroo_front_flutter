import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import 'trajet_models.dart';
import 'ride_route_column.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.vehicleType,
                        style: AppTextStyles.bodyLarge(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.vehicleName,
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${ride.price.toStringAsFixed(2)}',
                      style: AppTextStyles.priceMedium(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _IconLabel(
                        icon: Icons.calendar_today_rounded, label: ride.date),
                    const SizedBox(height: 4),
                    _IconLabel(
                        icon: Icons.access_time_rounded, label: ride.time),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            RideRouteColumn(ride: ride),
            const SizedBox(height: 16),
            _ActionButton(ride: ride),
          ],
        ),
      ),
    );
  }
}

// ── Small icon + label ────────────────────────────────────────────────────────

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.subtext(context)),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodySmall(context).copyWith(fontSize: 12)),
      ],
    );
  }
}

// ── Action buttons per status ─────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final RideModel ride;
  const _ActionButton({required this.ride});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    switch (ride.status) {

      // ── Upcoming: Track + Chat ─────────────────────────────
      case RideStatus.upcoming:
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => AppRouter.push(context, AppRouter.trackRide,
                    args: {
                      'rideId':         ride.rideId         ?? '',
                      'pickupLat':      ride.pickupLat      ?? 36.8189,
                      'pickupLon':      ride.pickupLon      ?? 10.1658,
                      'dropoffLat':     ride.dropoffLat     ?? 36.8300,
                      'dropoffLon':     ride.dropoffLon     ?? 10.1750,
                      'pickupAddress':  ride.pickup,
                      'dropoffAddress': ride.dropoff,
                      'driverName':     ride.driverName     ?? 'Driver',
                      'vehicleName':    ride.vehicleName,
                      'vehicleColor':   ride.vehicleColor   ?? '',
                      'plateNumber':    ride.plateNumber    ?? '',
                      'etaMins':        ride.etaMins,
                    }),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.near_me_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(t('track_ride'),
                          style: AppTextStyles.buttonPrimary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Chat button
            GestureDetector(
              onTap: () => AppRouter.push(context, AppRouter.chat),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Center(
                  child: ImageIcon(
                    const AssetImage('images/icons/chat.png'),
                    size: 22,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          ],
        );

      // ── Completed: Book again ──────────────────────────────
      case RideStatus.completed:
        return GestureDetector(
          onTap: () {},
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                t('book_again'),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
        );

      // ── Cancelled ──────────────────────────────────────────
      case RideStatus.cancelled:
        return Container(
          height: 46,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              t('cancelled'),
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        );

      // ── Pending payment ────────────────────────────────────
      case RideStatus.pendingPayment:
        return GestureDetector(
          onTap: () => AppRouter.push(context, AppRouter.rideDetails),
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_rounded,
                    color: Color(0xFFFF6B00), size: 18),
                const SizedBox(width: 8),
                Text(
                  t('complete_payment'),
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B00),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}