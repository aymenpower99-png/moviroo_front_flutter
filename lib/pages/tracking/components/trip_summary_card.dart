import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import 'pickup_drop_row.dart';
import '../models/ride_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Trip summary card — shown in the bottom sheet when rideEnded
// ─────────────────────────────────────────────────────────────────────────────

class TripSummaryCard extends StatefulWidget {
  final RideState rideState;
  final String pickupLabel;
  final String dropLabel;
  final VoidCallback? onContinue;

  const TripSummaryCard({
    super.key,
    required this.rideState,
    required this.pickupLabel,
    required this.dropLabel,
    this.onContinue,
  });

  @override
  State<TripSummaryCard> createState() => _TripSummaryCardState();
}

class _TripSummaryCardState extends State<TripSummaryCard> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const green = Color(0xFF4ADE80);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, color: green, size: 48),
              const SizedBox(height: 8),
              Text(
                l10n.translate('trip_completed'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Stats: distance + arrival time
        Row(
          children: [
            Expanded(
              child: TripStatChip(
                icon: Icons.straighten_rounded,
                value: widget.rideState.distanceLeft,
                label: l10n.translate('distance'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TripStatChip(
                icon: Icons.access_time_rounded,
                value: widget.rideState.arrivalTime,
                label: l10n.translate('arrived_at_label'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Divider(color: AppColors.border(context)),
        const SizedBox(height: 16),

        // Driver + rating
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.35),
                  width: 2,
                ),
                color: AppColors.iconBg(context),
              ),
              child: ClipOval(
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryPurple,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.rideState.driverName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                      if (widget.rideState.driverRating > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              widget.rideState.driverRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtext(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('rate_your_driver'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.subtext(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i < _rating
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD1D5DB),
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Divider(color: AppColors.border(context)),
        const SizedBox(height: 16),

        PickupDropRow(
          pickupLabel: widget.pickupLabel,
          dropLabel: widget.dropLabel,
        ),

        const SizedBox(height: 20),

        // Purple continue button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onContinue ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              l10n.translate('continue'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip (distance / time)
// ─────────────────────────────────────────────────────────────────────────────

class TripStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const TripStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.subtext(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
