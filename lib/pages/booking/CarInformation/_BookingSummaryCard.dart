import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '_SummaryCard.dart';

class BookingSummaryCard extends StatelessWidget {
  final int pax;
  final int bags;
  final int? seats;
  final String vehicleName;
  final String? carName;
  final String? imageUrl;

  const BookingSummaryCard({
    super.key,
    required this.pax,
    required this.bags,
    this.seats,
    required this.vehicleName,
    this.carName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final carNameValue = carName;

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Passenger info (separate from vehicle) ───────────
          

          
          // ── Vehicle info ─────────────────────────────────────
          Row(
            children: [
              imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      width: 120,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'images/bmw.png',
                        width: 120,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'images/bmw.png',
                      width: 120,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vehicleName.isNotEmpty)
                      Text(
                        vehicleName,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    if (carNameValue != null && carNameValue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        carNameValue,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.subtext(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Seats capacity (vehicle spec)
                        if (seats != null)
                          _InfoChip(
                            icon: Icons.event_seat_outlined,
                            label: '$seats ${t.translate('seats')}',
                          ),
                        // Bags
                        _InfoChip(
                          icon: Icons.luggage_outlined,
                          label: '$bags ${t.translate('chip_lug')}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
