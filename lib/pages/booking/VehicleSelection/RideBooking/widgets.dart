import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../_CarCard.dart';

/// Back button widget
class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

// ── Anchored Location Card ──────────────────────────────────────────────────

/// Compact location card that floats above a map marker.
/// The pointer triangle adapts its horizontal position so it always
/// points toward the marker, even when the card is clamped to screen edges.
class AnchoredLocationCard extends StatelessWidget {
  final Offset markerScreen;
  final double screenWidth;
  final String name;
  final String subtitle;
  final bool isPickup;

  static const double _cardWidth = 190;
  static const double _triangleW = 14;
  static const double _triangleH = 7;
  static const double _gap = 4;
  static const double _edgePad = 10;

  const AnchoredLocationCard({
    required this.markerScreen,
    required this.screenWidth,
    required this.name,
    required this.subtitle,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp card left so it stays on screen
    double left = markerScreen.dx - _cardWidth / 2;
    left = left.clamp(_edgePad, screenWidth - _cardWidth - _edgePad);

    // Estimate total height: body (~46) + triangle (7) + gap (4)
    const bodyH = 46.0;
    const totalH = bodyH + _triangleH + _gap;
    double top = markerScreen.dy - totalH;
    if (top < 4) top = 4;

    // Triangle offset: how far the marker center is from card left edge
    final triangleCenterX = (markerScreen.dx - left).clamp(
      _triangleW / 2 + 8,
      _cardWidth - _triangleW / 2 - 8,
    );

    final surfaceColor = AppColors.surface(context);

    return Positioned(
      left: left,
      top: top,
      width: _cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card body ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Dot indicator (purple for pickup, red-ish for dropoff)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isPickup
                        ? AppColors.primaryPurple
                        : AppColors.primaryPurple.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 10,
                            color: AppColors.subtext(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Adaptive triangle pointer ──────
          SizedBox(
            width: _cardWidth,
            height: _triangleH,
            child: CustomPaint(
              painter: _AdaptiveTrianglePainter(
                color: surfaceColor,
                triangleCenterX: triangleCenterX,
                triangleWidth: _triangleW,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a downward triangle at [triangleCenterX] within the available width.
class _AdaptiveTrianglePainter extends CustomPainter {
  final Color color;
  final double triangleCenterX;
  final double triangleWidth;

  const _AdaptiveTrianglePainter({
    required this.color,
    required this.triangleCenterX,
    required this.triangleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final half = triangleWidth / 2;
    final path = Path()
      ..moveTo(triangleCenterX - half, 0)
      ..lineTo(triangleCenterX, size.height)
      ..lineTo(triangleCenterX + half, 0)
      ..close();

    canvas.drawShadow(path, Colors.black, 3.0, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AdaptiveTrianglePainter old) =>
      old.color != color || old.triangleCenterX != triangleCenterX;
}

// ── Sheet Header ────────────────────────────────────────────────────────────

/// Sheet Header (pill + title + divider).
///
/// This is a *purely visual* widget. The drag-to-expand/collapse behaviour is
/// driven by the parent `DraggableScrollableSheet` through the scroll controller
/// it injects into the `CustomScrollView`. Because this header lives inside that
/// scrollable, dragging on the pill is automatically translated into sheet
/// movement at the sheet's boundaries (collapsed ↔ expanded).
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        // Pill / drag handle (visual only — the scrollable handles the drag)
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Title
        Center(
          child: Text(
            t.translate('choose_a_ride'),
            style: AppTextStyles.pageTitle(
              context,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: AppColors.border(context)),
      ],
    );
  }
}

// ── Confirm Bar ─────────────────────────────────────────────────────────────

/// Confirm Bar (sticky bottom)
class ConfirmBar extends StatelessWidget {
  final CarOption car;
  final double bottomPad;
  final VoidCallback onConfirm;

  const ConfirmBar({
    required this.car,
    required this.bottomPad,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Text(
                '${t.translate('confirm_ride')} ${car.name}',
                style: AppTextStyles.buttonPrimary,
              ),
              Text(
                car.price,
                style: AppTextStyles.buttonPrimary.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
