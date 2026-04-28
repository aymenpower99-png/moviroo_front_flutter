import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pickup / Drop-off row
// ─────────────────────────────────────────────────────────────────────────────

class PickupDropRow extends StatelessWidget {
  final String pickupLabel;
  final String dropLabel;

  const PickupDropRow({
    super.key,
    required this.pickupLabel,
    required this.dropLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final purple = AppColors.primaryPurple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: circles + dashed connector
          SizedBox(
            width: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: purple,
                  ),
                ),
                SizedBox(
                  width: 2,
                  height: 40,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: AppColors.border(context),
                    ),
                  ),
                ),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: purple, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right column: labels + addresses
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('pickup'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: purple,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  pickupLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.translate('dropoff'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: purple,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dropLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed line painter
// ─────────────────────────────────────────────────────────────────────────────

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashH = 4.0;
    const gapH = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashH).clamp(0, size.height)),
        paint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter old) => old.color != color;
}
