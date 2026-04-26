import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../_CarCard.dart';
import 'widgets.dart';

/// The bottom sheet for the [RideBookingPage].
///
/// Owns its own drag state ([_sheetHeight], [_dragStartY], [_dragStartHeight])
/// and renders the pill / title / car cards / sticky confirm bar.
///
/// IMPORTANT: this widget returns a [Positioned], so it must be placed inside
/// a [Stack] in the parent.
class RideBookingSheet extends StatefulWidget {
  /// Whether vehicle prices are still loading.
  final bool isLoadingPrices;

  /// Cars to display in the sheet.
  final List<CarOption> cars;

  /// Index of the currently selected car (only valid when [cars] is non-empty).
  final int selectedCarIndex;

  /// Called when a car card is tapped, with the index that was tapped.
  final ValueChanged<int> onCarSelected;

  /// Called when the user taps the sticky confirm bar.
  final VoidCallback onConfirm;

  const RideBookingSheet({
    super.key,
    required this.isLoadingPrices,
    required this.cars,
    required this.selectedCarIndex,
    required this.onCarSelected,
    required this.onConfirm,
  });

  @override
  State<RideBookingSheet> createState() => _RideBookingSheetState();
}

class _RideBookingSheetState extends State<RideBookingSheet> {
  // ── Layout measurements ────────────────────────────────────────────────────
  // These are the *actual* fixed heights of the widgets stacked inside the sheet.
  // They were derived directly from the widget source (CarCard / SheetHeader /
  // ConfirmBar) so the per-card snap math is exact, not approximate.
  //
  //   CarCard     : margin 5+5 + padding 13+13 + content (image pod 66) = 102 px
  //   SheetHeader : 10 + pill 4 + 14 + title ~28 + 8 + divider 1         ≈  65 px
  //   ConfirmBar  : padding 12 + button 54 + padding 12                  =  78 px
  //   Sliver top padding                                                  =   4 px
  //
  static const double _cardHeightPx = 102.0;
  static const double _headerHeightPx = 65.0;
  static const double _sliverTopPadPx = 4.0;
  static const double _confirmBarHeightPx = 78.0;

  // Manual sheet drag state
  double _sheetHeight = 0.35; // Initial height (fraction of screen)
  double _dragStartY = 0.0;
  double _dragStartHeight = 0.35;

  CarOption? get _selectedCar {
    if (widget.cars.isEmpty) return null;
    return widget.cars[widget.selectedCarIndex];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final t = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // ── Sheet height bounds ─────────────────────────────────────────────────
    // The minimum sheet height is the EXACT space needed to show:
    //   pill + title (SheetHeader) + 1 full CarCard + ConfirmBar (+ safe area)
    // Dragging below this point is impossible — the floor is fixed.
    // The maximum is 85% of the screen.
    final reservePx =
        _headerHeightPx + _sliverTopPadPx + _confirmBarHeightPx + bottomPad;
    final oneCardSize = (reservePx + _cardHeightPx) / screenHeight;
    final minSheetFraction = oneCardSize.clamp(0.20, 0.85);
    const maxSheetFraction = 0.85;

    // Initialize sheet height on first build, then clamp every build to
    // protect against orientation/window-size changes pushing it below the floor.
    if (_sheetHeight == 0.35) {
      _sheetHeight = minSheetFraction;
    } else {
      _sheetHeight = _sheetHeight.clamp(minSheetFraction, maxSheetFraction);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: screenHeight * _sheetHeight,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _dragStartY = details.globalPosition.dy;
          _dragStartHeight = _sheetHeight;
        },
        onVerticalDragUpdate: (details) {
          final deltaY = details.globalPosition.dy - _dragStartY;
          final deltaHeight = -deltaY / screenHeight;
          // Hard floor: cannot drag below the "1 card + header + confirm
          // bar" position. Hard ceiling: 85% of screen.
          final newHeight = (_dragStartHeight + deltaHeight).clamp(
            minSheetFraction,
            maxSheetFraction,
          );
          setState(() {
            _sheetHeight = newHeight;
          });
        },
        child: ClipRRect(
          // Hard-edge clipping: nothing inside the sheet can ever paint
          // outside this rounded rectangle. Cards, confirm bar, anything —
          // if it spills past the sheet's edge, it is clipped, not drawn.
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            // ── Strict layout with absolute positioning ──
            // The sheet has a fixed height (screenHeight * _sheetHeight).
            // The ConfirmBar is positioned absolutely at the bottom.
            // ALL car cards are always rendered. The cards area is strictly
            // clipped to the space between the SheetHeader and the
            // ConfirmBar — dragging the pill simply uncovers/covers cards
            // by changing the visible portion of the sheet.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sheetHeight = constraints.maxHeight;
                final confirmBarTotalHeight = _selectedCar != null
                    ? _confirmBarHeightPx + bottomPad
                    : 0.0;
                // Available space for cards = sheet - header - confirm bar
                final cardsAreaHeight =
                    (sheetHeight - _headerHeightPx - confirmBarTotalHeight)
                        .clamp(0.0, double.infinity);

                // ── Card content ──
                // ALL cards are always rendered. The ClipRect on the cards
                // area + OverflowBox lets the column use its natural full
                // height, but only the portion that fits is visible.
                // Dragging the pill changes cardsAreaHeight, which uncovers
                // or covers more cards — but every card always exists.
                Widget content;
                if (widget.isLoadingPrices) {
                  content = const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (widget.cars.isEmpty) {
                  content = Center(
                    child: Text(
                      t.translate('no_vehicles_available'),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  );
                } else {
                  content = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      for (
                        int index = 0;
                        index < widget.cars.length;
                        index++
                      )
                        CarCard(
                          car: widget.cars[index],
                          isSelected: widget.selectedCarIndex == index,
                          onTap: () => widget.onCarSelected(index),
                        ),
                    ],
                  );
                }

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // ── SheetHeader at top ──
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SheetHeader(),
                    ),

                    // ── Cards area: strictly constrained, hard-clipped ──
                    // All cards exist in the tree. The cards container
                    // hard-clips its content at its own boundary — when
                    // the sheet height isn't tall enough to fit the next
                    // card, that card is cleanly cut off instead of
                    // bleeding outside and triggering an overflow error.
                    //
                    // We use a Stack with hard-edge clipping and an
                    // unbounded Positioned child so the cards Column can
                    // be its full natural height, but anything past the
                    // Stack's edge is clipped invisibly.
                    Positioned(
                      top: _headerHeightPx,
                      left: 0,
                      right: 0,
                      height: cardsAreaHeight,
                      child: ClipRect(
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: content,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── ConfirmBar absolutely positioned at bottom ──
                    if (_selectedCar != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ConfirmBar(
                          car: _selectedCar!,
                          bottomPad: bottomPad,
                          onConfirm: widget.onConfirm,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
