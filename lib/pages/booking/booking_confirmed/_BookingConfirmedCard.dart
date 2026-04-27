import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_RouteRows.dart';
import '_StatColumn.dart';

class BookingConfirmedCard extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final String eta;
  final String distance;
  final String pax;
  final bool isCash;

  const BookingConfirmedCard({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.eta,
    required this.distance,
    required this.pax,
    required this.isCash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: RouteRows(
              pickupAddress: pickupAddress,
              dropoffAddress: dropoffAddress,
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: AppColors.border(context)),

          // ── 3. Trip info row (3 columns) ──────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: StatColumn(label: 'ETA', value: eta),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.border(context),
                  ),
                  Expanded(
                    child: StatColumn(label: 'DISTANCE', value: distance),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.border(context),
                  ),
                  Expanded(
                    child: StatColumn(label: 'PAX', value: pax),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: AppColors.border(context)),

          // ── 4. Payment Method row ─────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  isCash ? Icons.money : Icons.credit_card_rounded,
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
    );
  }
}
