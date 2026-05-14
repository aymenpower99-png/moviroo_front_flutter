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
  final String? classId; // real backend UUID — null for static/sample data
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
    this.classId,
    this.eta,
    this.duration,
    this.badge,
  });
}

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

// ── Adaptive car image: handles network URLs and local assets ───────────────
class _AdaptiveCarImage extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _AdaptiveCarImage({
    this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  bool get _isNetwork =>
      image != null &&
      (image!.startsWith('http://') || image!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return _FallbackCarImage(width: width, height: height);
    }
    if (_isNetwork) {
      return Image.network(
        image!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _FallbackCarImage(width: width, height: height),
      );
    }
    return Image.asset(
      image!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          _FallbackCarImage(width: width, height: height),
    );
  }
}

class _FallbackCarImage extends StatelessWidget {
  final double? width;
  final double? height;
  const _FallbackCarImage({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 80,
      height: height ?? 58,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_rounded,
        size: 40,
        color: AppColors.subtext(context),
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
      width: 120,
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Shadow ellipse beneath car
          Container(
            height: 14,
            width: 95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          _AdaptiveCarImage(
            image: image,
            width: 120,
            height: 70,
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

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }

  Future<void> _loadClassDetails() async {
    setState(() => _isLoading = true);

    final classId = widget.car.classId;
    if (classId == null || classId.isEmpty) {
      debugPrint(
        '[_CarDetailSheet] No classId available for ${widget.car.name}',
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      debugPrint(
        '[_CarDetailSheet] Fetching details for classId=$classId',
      );
      final details = await _vehicleClassesService.getClassDetails(classId);
      debugPrint(
        '[_CarDetailSheet] API details: ${details?.features.toString()}',
      );
      if (!mounted) return;
      setState(() {
        _classDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[_CarDetailSheet] Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<String> _getFeatureLabels() {
    if (_classDetails == null) return [];

    final features = <String>[];
    final f = _classDetails!.features;

    if (f.ac == true) features.add('Air conditioning');
    if (f.wifi == true) features.add('Free WiFi onboard');
    if (f.water == true) features.add('Complimentary water');
    if (f.meetAndGreet == true) features.add('Meet & greet service');
    if (f.doorToDoor == true) features.add('Door-to-door service');
    if (f.freeWaitingTime != null && f.freeWaitingTime! > 0) {
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
              height: 160,
              child: _AdaptiveCarImage(
                image: widget.car.image,
                height: 160,
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

          // Data loaded — only show sections backed by real API data
          if (!_isLoading && _classDetails != null) ...[
            // Spec pills — conditionally render each if the backend provided it
            Builder(
              builder: (context) {
                final f = _classDetails!.features;
                final pills = <Widget>[];

                if (f.seats != null) {
                  pills.add(
                    _SpecPill(
                      icon: Icons.person_outline_rounded,
                      label: '${f.seats}',
                    ),
                  );
                }
                if (f.bags != null) {
                  if (pills.isNotEmpty) pills.add(const SizedBox(width: 12));
                  pills.add(
                    _SpecPill(
                      icon: Icons.luggage_outlined,
                      label: '${f.bags}',
                    ),
                  );
                }
                if (f.ac == true) {
                  if (pills.isNotEmpty) pills.add(const SizedBox(width: 12));
                  pills.add(
                    const _SpecPill(
                      icon: Icons.ac_unit_outlined,
                      label: 'A/C',
                    ),
                  );
                }

                if (pills.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pills,
                  ),
                );
              },
            ),
            if (_classDetails!.features.seats != null ||
                _classDetails!.features.bags != null ||
                _classDetails!.features.ac == true)
              const SizedBox(height: 24),
            if (_getFeatureLabels().isNotEmpty) ...[
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
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryPurple,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.check,
            size: 14,
            color: AppColors.primaryPurple,
          ),
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
