import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '../../../../services/vehicle_pricing_service.dart';
import '_CarCard.dart';

class RideBookingPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLon;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLon;
  final String dropoffAddress;

  const RideBookingPage({
    super.key,
    required this.pickupLat,
    required this.pickupLon,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.dropoffAddress,
  });

  @override
  State<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends State<RideBookingPage> {
  // ignore: unused_field
  mbx.MapboxMap? _mapboxMap; // Will be used for markers and polyline
  int _selectedCarIndex = 0;
  VehiclePricingResponse? _pricingResponse;
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _loadVehiclePrices();
  }

  Future<void> _loadVehiclePrices() async {
    final service = VehiclePricingService();
    final response = await service.getVehiclePrices(
      pickupLat: widget.pickupLat,
      pickupLon: widget.pickupLon,
      dropoffLat: widget.dropoffLat,
      dropoffLon: widget.dropoffLon,
    );
    if (mounted) {
      setState(() {
        _pricingResponse = response;
        _isLoadingPrices = false;
      });
    }
  }

  void _onMapCreated(mbx.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    mapboxMap.compass.updateSettings(mbx.CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(mbx.ScaleBarSettings(enabled: false));
    // TODO: Add markers and polyline after fixing Mapbox API
  }

  void _onStyleLoaded(mbx.StyleLoadedEventData _) {
    // TODO: Add route overlay after fixing Mapbox API
  }

  List<CarOption> get _filteredCars {
    if (_pricingResponse == null || _pricingResponse!.vehicleClasses.isEmpty) {
      return [];
    }

    return _pricingResponse!.vehicleClasses
        .map(
          (vc) => CarOption(
            name: vc.name,
            image: vc.imageUrl ?? '',
            seats: vc.seats,
            bags: vc.bags,
            price: '${vc.priceTnd} TND',
            eta: '${vc.durationMin} min',
            duration: '${vc.durationMin} min',
            classCategory: 'All',
            badge: '',
          ),
        )
        .toList();
  }

  CarOption? get _selectedCar {
    if (_filteredCars.isEmpty) return null;
    return _filteredCars[_selectedCarIndex];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Mapbox map (full screen) ─────────────────────
          Positioned.fill(
            child: mbx.MapWidget(
              styleUri: mbx.MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              cameraOptions: mbx.CameraOptions(
                center: mbx.Point(
                  coordinates: mbx.Position(
                    (widget.pickupLon + widget.dropoffLon) / 2,
                    (widget.pickupLat + widget.dropoffLat) / 2,
                  ),
                ),
                zoom: 12.0,
                bearing: 0.0,
                pitch: 0.0,
              ),
            ),
          ),

          // ── Back button ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _BackButton(),
          ),

          // ── Floating location cards ──────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LocationCard(
                  label: t.translate('pickup'),
                  address: widget.pickupAddress,
                  isPickup: true,
                ),
                const SizedBox(height: 8),
                _LocationCard(
                  label: t.translate('dropoff'),
                  address: widget.dropoffAddress,
                  isPickup: false,
                ),
              ],
            ),
          ),

          // ── Bottom sheet ─────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.20,
            maxChildSize: 0.85,
            snap: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                    _SheetHeader(),

                    // ── Scrollable car list ─────────────────
                    Expanded(
                      child: _isLoadingPrices
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredCars.isEmpty
                          ? Center(
                              child: Text(
                                t.translate('no_vehicles_available'),
                                style: AppTextStyles.bodyMedium(context),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              itemCount: _filteredCars.length,
                              itemBuilder: (context, index) {
                                final car = _filteredCars[index];
                                return CarCard(
                                  car: car,
                                  isSelected: _selectedCarIndex == index,
                                  onTap: () =>
                                      setState(() => _selectedCarIndex = index),
                                );
                              },
                            ),
                    ),

                    // ── Sticky confirm button ───────────────
                    if (_selectedCar != null)
                      _ConfirmBar(
                        car: _selectedCar!,
                        bottomPad: bottomPad,
                        onConfirm: () {
                          // TODO: Navigate to booking confirmation
                          Navigator.pop(context);
                        },
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
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

// ── Location Card ────────────────────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  final String label;
  final String address;
  final bool isPickup;

  const _LocationCard({
    required this.label,
    required this.address,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isPickup
                  ? const Color(0xFF4A5FD5)
                  : const Color(0xFFA855F7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontSize: 11, color: AppColors.subtext(context)),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 150,
                child: Text(
                  address,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sheet Header (drag handle + title) ───────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

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

// ── Confirm Bar (sticky bottom) ───────────────────────────────────────────────
class _ConfirmBar extends StatelessWidget {
  final CarOption car;
  final double bottomPad;
  final VoidCallback onConfirm;

  const _ConfirmBar({
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
