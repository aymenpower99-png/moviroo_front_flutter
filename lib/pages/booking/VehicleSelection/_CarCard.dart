import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/currency/currency_service.dart';
import '../../../../services/vehicle_classes/vehicle_classes_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class CarOption {
  final String name;
  final String subtitle;
  final String image;
  final int seats;
  final int bags;
  final String price; // fallback string for static/sample data
  final double priceTndRaw; // raw TND amount for live conversion
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
    this.priceTndRaw = 0.0,
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
    final currency = context.watch<CurrencyService>();
    final displayPrice = widget.car.priceTndRaw > 0
        ? currency.format(widget.car.priceTndRaw)
        : widget.car.price;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? (isDark ? const Color(0xFF1C1C22) : const Color(0xFFF8F8FA))
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
                    style: AppTextStyles.vehicleClassName(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: AppColors.primaryPurple,
                      ),
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
                      Icon(
                        Icons.cases_outlined,
                        size: 15,
                        color: AppColors.primaryPurple,
                      ),
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
                ],
              ),
            ),

            // ── Price ─────────────────────────────────────────
            Text(
              displayPrice,
              style: AppTextStyles.priceMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
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
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
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
            errorBuilder: (_, _, _) => Icon(
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

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────
class _CarDetailSheet extends StatefulWidget {
  final CarOption car;
  const _CarDetailSheet({required this.car});

  @override
  State<_CarDetailSheet> createState() => _CarDetailSheetState();
}

class _CarDetailSheetState extends State<_CarDetailSheet> {
  final VehicleClassesService _vehicleClassesService = VehicleClassesService();
  VehicleClassDetail? _classDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }

  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: fetch all active classes to resolve name → ID
      final activeClasses = await _vehicleClassesService.getActiveClasses();
      debugPrint(
        '[_CarDetailSheet] Active classes: ${activeClasses.map((c) => c.name).toList()}',
      );

      // Step 2: find the class whose name matches the car's category or name
      VehicleClass matchedClass = activeClasses.firstWhere(
        (c) =>
            c.name.toLowerCase().trim() ==
            widget.car.classCategory.toLowerCase().trim(),
        orElse: () => VehicleClass(id: '', name: '', multiplier: 0),
      );

      // Fallback: try matching against the display name (e.g. "Standard XL")
      if (matchedClass.id.isEmpty) {
        matchedClass = activeClasses.firstWhere(
          (c) =>
              c.name.toLowerCase().trim() ==
              widget.car.name.toLowerCase().trim(),
          orElse: () => VehicleClass(id: '', name: '', multiplier: 0),
        );
      }

      debugPrint(
        '[_CarDetailSheet] Matched class: ${matchedClass.name} (id=${matchedClass.id})',
      );

      VehicleClassDetail? details;
      if (matchedClass.id.isNotEmpty) {
        // Step 3: fetch details using the real class ID
        details = await _vehicleClassesService.getClassDetails(
          matchedClass.id,
        );
        debugPrint(
          '[_CarDetailSheet] API details: ${details?.features.toString()}',
        );
      }

      if (!mounted) return;

      // Step 4: if API returned nothing, build fallback from static CarOption data
      if (details == null) {
        details = _buildFallbackDetails();
        debugPrint(
          '[_CarDetailSheet] Using fallback for ${widget.car.name}',
        );
      }

      setState(() {
        _classDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[_CarDetailSheet] Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Still show fallback data instead of a raw error
        _classDetails = _buildFallbackDetails();
      });
    }
  }

  /// Build a realistic VehicleClassDetail fallback per tier so the sheet
  /// never shows empty specs even when the API is unreachable.
  VehicleClassDetail _buildFallbackDetails() {
    final name = widget.car.name.toLowerCase();

    // Determine tier defaults
    final bool wifi = name.contains('business') ||
        name.contains('premium') ||
        name.contains('standard');
    final bool water = name.contains('business') || name.contains('premium');
    final bool meetAndGreet =
        name.contains('business') || name.contains('premium');
    final int freeWaitingTime = name.contains('premium')
        ? 15
        : name.contains('business') || name.contains('van')
            ? 10
            : 5;

    return VehicleClassDetail(
      id: '',
      name: widget.car.name,
      imageUrl: null,
      multiplier: 1.0,
      features: VehicleFeatures(
        seats: widget.car.seats,
        bags: widget.car.bags,
        wifi: wifi,
        ac: true,
        water: water,
        freeWaitingTime: freeWaitingTime,
        doorToDoor: true,
        meetAndGreet: meetAndGreet,
        extraFeatures: [],
        extraServices: [],
      ),
    );
  }

  List<String> _getFeatureLabels() {
    if (_classDetails == null) return [];

    final features = <String>[];
    final f = _classDetails!.features;

    if (f.ac) features.add('Air conditioning');
    if (f.wifi) features.add('Free WiFi onboard');
    if (f.water) features.add('Complimentary water');
    if (f.meetAndGreet) features.add('Meet & greet service');
    if (f.doorToDoor) features.add('Door-to-door service');
    if (f.freeWaitingTime > 0) {
      features.add('${f.freeWaitingTime} min free waiting time');
    }

    // Add extra features that are enabled
    for (final extra in f.extraFeatures) {
      if (extra.enabled && extra.name.isNotEmpty) {
        features.add(extra.name);
      }
    }

    // Add extra services that are enabled
    for (final extra in f.extraServices) {
      if (extra.enabled && extra.name.isNotEmpty) {
        features.add(extra.name);
      }
    }

    debugPrint('[_CarDetailSheet] Feature labels: $features');
    return features;
  }

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
              child: Image.asset(
                widget.car.image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.directions_car,
                  size: 80,
                  color: AppColors.subtext(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.car.name,
            style: AppTextStyles.bookingId(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          if (widget.car.subtitle.isNotEmpty)
            Text(
              widget.car.subtitle,
              style: AppTextStyles.vehicleClassDesc(context),
            ),
          const SizedBox(height: 24),

          // Loading state
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),

          // Error state
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.error),
              ),
            ),

          // Data loaded
          if (!_isLoading && _classDetails != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpecPill(
                    icon: Icons.person_outline_rounded,
                    label: '${_classDetails!.features.seats}',
                  ),
                  const SizedBox(width: 12),
                  _SpecPill(
                    icon: Icons.luggage_outlined,
                    label: '${_classDetails!.features.bags}',
                  ),
                  const SizedBox(width: 12),
                  _SpecPill(
                    icon: Icons.ac_unit_outlined,
                    label: _classDetails!.features.ac ? 'A/C' : 'No A/C',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(
              height: 1,
              color: AppColors.border(context),
              indent: 24,
              endIndent: 24,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: _getFeatureLabels()
                    .map(
                      (label) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FeatureRow(label: label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

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
                          color: AppColors.primaryPurple,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonPrimary.copyWith(
                          color: AppColors.primaryPurple,
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: AppTextStyles.buttonPrimary,
                      ),
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
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(fontSize: 13, color: AppColors.text(context)),
        ),
      ],
    );
  }
}
