import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_CarCard.dart';
import '_ClassFilterBar.dart';

class VehicleSelectionPage extends StatefulWidget {
  const VehicleSelectionPage({super.key});

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  int _selectedCarIndex = 0;
  String _selectedClass = 'All';

  List<CarOption> get _filteredCars {
    if (_selectedClass == 'All') return cars;
    return cars
        .where((c) =>
            c.classCategory.toLowerCase() == _selectedClass.toLowerCase())
        .toList();
  }

  CarOption get _selectedCar => cars[_selectedCarIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Map background (full screen) ────────────────────
          Positioned.fill(
            child: _MapBackground(isDark: isDark),
          ),

          // ── Back button ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _BackButton(),
          ),

          // ── Bottom sheet ────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.30,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.30, 0.55, 0.93],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── Non-scrolling sticky header ──────────
                    _SheetHeader(
                      selectedClass: _selectedClass,
                      onClassSelected: (c) =>
                          setState(() => _selectedClass = c),
                    ),

                    // ── Scrollable car list ──────────────────
                    Expanded(
                      child: _filteredCars.isEmpty
                          ? Center(
                              child: Text(
                                'No vehicles in this class',
                                style: AppTextStyles.bodyMedium(context),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 8),
                              itemCount: _filteredCars.length,
                              itemBuilder: (context, index) {
                                final car = _filteredCars[index];
                                final globalIndex = cars.indexOf(car);
                                return CarCard(
                                  car: car,
                                  isSelected:
                                      _selectedCarIndex == globalIndex,
                                  onTap: () => setState(
                                      () => _selectedCarIndex = globalIndex),
                                );
                              },
                            ),
                    ),

                    // ── Sticky confirm button ────────────────
                    _ConfirmBar(
                      car: _selectedCar,
                      bottomPad: bottomPad,
                      onConfirm: () =>
                          Navigator.pushNamed(context, '/booking',
                              arguments: _selectedCar),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Map Background ────────────────────────────────────────────────────────────
class _MapBackground extends StatelessWidget {
  final bool isDark;
  const _MapBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(isDark: isDark),
      child: Container(),
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool isDark;
  const _MapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color =
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8F0D8),
    );

    // Water blob
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.20),
        width: size.width * 0.65,
        height: size.height * 0.38,
      ),
      Paint()
        ..color = isDark
            ? const Color(0xFF162032)
            : const Color(0xFFC5DDE8),
    );

    // Road grid
    final roadPaint = Paint()
      ..color =
          isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(0, size.height * (0.08 + i * 0.12)),
        Offset(size.width, size.height * (0.06 + i * 0.13)),
        roadPaint,
      );
    }
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * (0.08 + i * 0.18), 0),
        Offset(size.width * (0.04 + i * 0.20), size.height),
        roadPaint,
      );
    }

    // Route
    final routePaint = Paint()
      ..color = const Color(0xFF4A5FD5)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path()
      ..moveTo(size.width * 0.17, size.height * 0.11)
      ..cubicTo(
        size.width * 0.35, size.height * 0.25,
        size.width * 0.55, size.height * 0.50,
        size.width * 0.82, size.height * 0.78,
      );
    canvas.drawPath(routePath, routePaint);

    // Origin dot
    canvas.drawCircle(Offset(size.width * 0.17, size.height * 0.11), 7,
        Paint()..color = const Color(0xFF4A5FD5));
    canvas.drawCircle(Offset(size.width * 0.17, size.height * 0.11), 4,
        Paint()..color = Colors.white);

    // Destination dot
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.78), 8,
        Paint()..color = const Color(0xFFA855F7));
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.78), 4,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Back Button ───────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
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
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 17, color: AppColors.text(context)),
      ),
    );
  }
}

// ── Sheet Header (drag handle + title + filter) ───────────────────────────────
class _SheetHeader extends StatelessWidget {
  final String selectedClass;
  final ValueChanged<String> onClassSelected;

  const _SheetHeader({
    required this.selectedClass,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
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
            'Choose a ride',
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Filter chips
        ClassFilterBar(
          selectedClass: selectedClass,
          onClassSelected: onClassSelected,
        ),
        const SizedBox(height: 8),

        Divider(height: 1, color: AppColors.border(context)),
      ],
    );
  }
}

// ── Confirm Bar (sticky bottom) ───────────────────────────────────────────────
class _ConfirmBar extends StatelessWidget {
  final CarOption car;
  final double bottomPad;
  final VoidCallback onConfirm;

  const _ConfirmBar({required this.car, required this.bottomPad, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
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
                'Confirm ${car.name}',
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