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

/// Anchored Location Card (floats above a marker on the map)
class AnchoredLocationCard extends StatelessWidget {
  /// Screen-space position of the marker this card should hover above.
  final Offset screen;

  /// Location name (bold, larger).
  final String name;

  /// "City, Country" line (smaller, lighter).
  final String subtitle;

  static const double _cardWidth = 210;
  static const double _triangleH = 8;
  static const double _gapAboveMarker = 6; // px between triangle tip and marker

  const AnchoredLocationCard({
    required this.screen,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Horizontally center the card on the marker, then clamp so it
    // never runs off-screen.
    final screenWidth = MediaQuery.of(context).size.width;
    double left = screen.dx - _cardWidth / 2;
    if (left < 8) left = 8;
    if (left + _cardWidth > screenWidth - 8) {
      left = screenWidth - _cardWidth - 8;
    }

    // Card body height (~56) + triangle (8) + gap (6) above marker
    const estimatedHeight = 56 + _triangleH + _gapAboveMarker;
    final top = screen.dy - estimatedHeight;

    final surfaceColor = AppColors.surface(context);

    return Positioned(
      left: left,
      top: top < 4 ? 4 : top,
      width: _cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Card body ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: two-line text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.subtext(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: chevron, vertically centered
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.subtext(context),
                ),
              ],
            ),
          ),

          // ── Triangle tail (speech-bubble pointer) ──────────
          CustomPaint(
            size: const Size(16, _triangleH),
            painter: TrianglePainter(color: surfaceColor),
          ),
        ],
      ),
    );
  }
}

/// Triangle painter for the speech-bubble tail
class TrianglePainter extends CustomPainter {
  final Color color;
  const TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    // Soft shadow beneath the triangle
    canvas.drawShadow(path, Colors.black, 4.0, false);
    // Fill the triangle with the card surface colour
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter old) => old.color != color;
}

/// Sheet Header (drag handle + title)
class SheetHeader extends StatelessWidget {
  const SheetHeader();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        const SizedBox(height: 10),
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
