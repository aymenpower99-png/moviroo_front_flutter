import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class CarOption {
  final String name;
  final String subtitle;
  final String image;
  final int seats;
  final int bags;
  final String price;
  final String classCategory;
  final String? eta;       
  final String? duration;  
  final String? badge;     

  const CarOption({
    required this.name,
    this.subtitle = '',
    required this.image,
    required this.seats,
    required this.bags,
    required this.price,
    required this.classCategory,
    this.eta,
    this.duration,
    this.badge,
  });
}

final List<CarOption> cars = [
  CarOption(
    name: 'Economy',
    subtitle: 'Toyota Corolla or similar',
    image: 'images/bmw.png',
    seats: 3,
    bags: 3,
    price: '€22.75',
    classCategory: 'Economy',
    eta: '19:57',
    duration: '4 min',
  ),
  CarOption(
    name: 'Standard',
    subtitle: 'Volkswagen Passat or similar',
    image: 'images/bmw.png',
    seats: 3,
    bags: 3,
    price: '€35.00',
    classCategory: 'Standard',
    eta: '19:55',
    duration: '3 min',
    badge: 'FASTER',
  ),
  CarOption(
    name: 'Standard XL',
    subtitle: 'Mercedes V Class or similar',
    image: 'images/bmw.png',
    seats: 7,
    bags: 7,
    price: '€35.00',
    classCategory: 'Standard',
    eta: '19:55',
    duration: '3 min',
  ),
  CarOption(
    name: 'Business',
    subtitle: 'Mercedes E Class, BMW 5 or similar',
    image: 'images/bmw.png',
    seats: 4,
    bags: 4,
    price: '€149.00',
    classCategory: 'Business',
    eta: '20:05',
    duration: '10 min',
  ),
  CarOption(
    name: 'Premium',
    subtitle: 'Mercedes S Class or similar',
    image: 'images/bmw.png',
    seats: 4,
    bags: 5,
    price: '€199.00',
    classCategory: 'Premium',
    eta: '20:10',
    duration: '15 min',
  ),
  CarOption(
    name: 'Van',
    subtitle: 'Mercedes V Class or similar',
    image: 'images/bmw.png',
    seats: 7,
    bags: 7,
    price: '€220.00',
    classCategory: 'Van',
    eta: '20:15',
    duration: '20 min',
  ),
];

// ── CarCard ───────────────────────────────────────────────────────────────────
class CarCard extends StatefulWidget {
  final CarOption car;
  final bool isSelected;
  final VoidCallback onTap;

  const CarCard({
    super.key,
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  void _handleTap() {
    if (!widget.isSelected) {
      widget.onTap();
    } else {
      _showDetailSheet(context);
    }
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CarDetailSheet(car: widget.car),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? (isDark
                  ? const Color(0xFF1C1C22)
                  : const Color(0xFFF8F8FA))
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primaryPurple
                : AppColors.border(context),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Car image with shadow pod ──────────────────────
            _CarImagePod(image: widget.car.image, isDark: isDark),
            const SizedBox(width: 14),

            // ── Name + seats/bags + badge ─────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.car.name,
                    style: AppTextStyles.vehicleClassName(context).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 15, color: AppColors.primaryPurple),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.car.seats}',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.cases_outlined,
                          size: 15, color: AppColors.primaryPurple),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.car.bags}',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                  if (widget.car.badge != null) ...[
                    const SizedBox(height: 7),
                    _FasterBadge(label: widget.car.badge!),
                  ],
                ],
              ),
            ),

            // ── Price ─────────────────────────────────────────
            Text(
              widget.car.price,
              style: AppTextStyles.priceMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Car image with dark ellipse shadow pod (like Uber/Bolt) ──────────────────
class _CarImagePod extends StatelessWidget {
  final String image;
  final bool isDark;
  const _CarImagePod({required this.image, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 66,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Shadow ellipse beneath car
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.55 : 0.18),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Image.asset(
            image,
            width: 100,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.directions_car_rounded,
              size: 48,
              color: AppColors.subtext(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FASTER badge ─────────────────────────────────────────────────────────────
class _FasterBadge extends StatelessWidget {
  final String label;
  const _FasterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────
class _CarDetailSheet extends StatelessWidget {
  final CarOption car;
  const _CarDetailSheet({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 120,
              child: Image.asset(car.image, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.directions_car, size: 80,
                    color: AppColors.subtext(context),
                  )),
            ),
          ),
          const SizedBox(height: 16),
          Text(car.name,
              style: AppTextStyles.bookingId(context).copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          if (car.subtitle.isNotEmpty)
            Text(car.subtitle,
                style: AppTextStyles.vehicleClassDesc(context)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SpecPill(
                    icon: Icons.person_outline_rounded,
                    label: '${car.seats}'),
                const SizedBox(width: 12),
                _SpecPill(icon: Icons.luggage_outlined, label: '${car.bags}'),
                const SizedBox(width: 12),
                const _SpecPill(icon: Icons.ac_unit_outlined, label: 'A/C'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: AppColors.border(context),
              indent: 24, endIndent: 24),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: const [
                _FeatureRow(icon: Icons.wifi_outlined,
                    label: 'Free WiFi onboard'),
                SizedBox(height: 10),
                _FeatureRow(icon: Icons.water_drop_outlined,
                    label: 'Complimentary water'),
                SizedBox(height: 10),
                _FeatureRow(icon: Icons.child_care_outlined,
                    label: 'Child seat available on request'),
                SizedBox(height: 10),
                _FeatureRow(icon: Icons.flight_outlined,
                    label: 'Flight tracking included'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        side: BorderSide(
                            color: AppColors.primaryPurple, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.buttonPrimary
                              .copyWith(color: AppColors.primaryPurple)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text('Continue',
                          style: AppTextStyles.buttonPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.iconBg(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
              child: Icon(icon, color: AppColors.primaryPurple, size: 24)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.bodySmall(context)
                .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primaryPurple),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.bodySmall(context)
                .copyWith(fontSize: 13, color: AppColors.text(context))),
      ],
    );
  }
}