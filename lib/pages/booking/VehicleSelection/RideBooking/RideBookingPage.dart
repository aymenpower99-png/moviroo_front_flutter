import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '../../../../services/vehicle_pricing/vehicle_pricing_service.dart';
import '../../../../services/mapbox/mapbox_service.dart';
import '../_CarCard.dart';
import 'map_manager.dart';
import 'widgets.dart';
import 'utils.dart';

class RideBookingPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final String? pickupAddress;
  final String? dropoffAddress;

  const RideBookingPage({
    super.key,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    this.pickupAddress,
    this.dropoffAddress,
  });

  @override
  State<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends State<RideBookingPage> {
  mbx.MapboxMap? _mapboxMap;
  MapManager? _mapManager;
  int _selectedCarIndex = 0;
  VehiclePricingResponse? _pricingResponse;
  bool _isLoadingPrices = true;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  String _pickupCity = '';
  String _pickupCountry = '';
  String _dropoffCity = '';
  String _dropoffCountry = '';
  bool _isLoadingAddresses = true;

  // Screen-space positions for card anchoring above markers
  Offset? _pickupScreen;
  Offset? _dropoffScreen;

  @override
  void initState() {
    super.initState();
    // Use passed display names immediately so user never sees stale data
    _pickupAddress = widget.pickupAddress ?? '';
    _dropoffAddress = widget.dropoffAddress ?? '';
    if (_pickupAddress.isNotEmpty && _dropoffAddress.isNotEmpty) {
      _isLoadingAddresses = false;
    }
    _loadVehiclePrices();
    _loadAddressDetails();
  }

  Future<void> _loadAddressDetails() async {
    // If we already have display names from the search screen, only fetch
    // city/country details. The display_name stays as-is for consistency.
    try {
      final results = await Future.wait([
        MapboxService.reverseGeocode(widget.pickupLat, widget.pickupLon),
        MapboxService.reverseGeocode(widget.dropoffLat, widget.dropoffLon),
      ]);
      final pickupPlace = results[0];
      final dropoffPlace = results[1];
      if (mounted) {
        setState(() {
          // Only override address if we didn't receive one from the search screen
          if (_pickupAddress.isEmpty) {
            _pickupAddress = pickupPlace?.placeName ?? 'Unknown location';
          }
          if (_dropoffAddress.isEmpty) {
            _dropoffAddress = dropoffPlace?.placeName ?? 'Unknown location';
          }
          _pickupCity = pickupPlace?.city ?? '';
          _pickupCountry = pickupPlace?.country ?? '';
          _dropoffCity = dropoffPlace?.city ?? '';
          _dropoffCountry = dropoffPlace?.country ?? '';
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading address details: $e');
      if (mounted) {
        setState(() {
          if (_pickupAddress.isEmpty) {
            _pickupAddress =
                'Location (${widget.pickupLat.toStringAsFixed(4)}, ${widget.pickupLon.toStringAsFixed(4)})';
          }
          if (_dropoffAddress.isEmpty) {
            _dropoffAddress =
                'Location (${widget.dropoffLat.toStringAsFixed(4)}, ${widget.dropoffLon.toStringAsFixed(4)})';
          }
          _isLoadingAddresses = false;
        });
      }
    }
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
  }

  void _onStyleLoaded(mbx.StyleLoadedEventData _) async {
    if (_mapboxMap == null) return;

    _mapManager = MapManager(
      mapboxMap: _mapboxMap!,
      pickupLat: widget.pickupLat,
      pickupLon: widget.pickupLon,
      dropoffLat: widget.dropoffLat,
      dropoffLon: widget.dropoffLon,
    );

    await _mapManager!.setup();
    _updateScreenPositions();
  }

  void _onCameraChanged(mbx.CameraChangedEventData _) {
    _updateScreenPositions();
  }

  Future<void> _updateScreenPositions() async {
    if (_mapManager == null) return;
    final positions = await _mapManager!.getScreenPositions();
    if (mounted && positions != null) {
      setState(() {
        _pickupScreen = positions.$1;
        _dropoffScreen = positions.$2;
      });
    }
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
  void dispose() {
    _mapManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final t = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

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
              onCameraChangeListener: _onCameraChanged,
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
            child: const BackButtonWidget(),
          ),

          // ── Pickup location card ─────
          if (_pickupScreen != null)
            AnchoredLocationCard(
              markerScreen: _pickupScreen!,
              screenWidth: screenWidth,
              name: _isLoadingAddresses && _pickupAddress.isEmpty
                  ? 'Loading...'
                  : _pickupAddress,
              subtitle: cityCountry(_pickupCity, _pickupCountry),
              isPickup: true,
            ),

          // ── Drop-off location card ─
          if (_dropoffScreen != null)
            AnchoredLocationCard(
              markerScreen: _dropoffScreen!,
              screenWidth: screenWidth,
              name: _isLoadingAddresses && _dropoffAddress.isEmpty
                  ? 'Loading...'
                  : _dropoffAddress,
              subtitle: cityCountry(_dropoffCity, _dropoffCountry),
              isPickup: false,
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
                    const SheetHeader(),

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
                      ConfirmBar(
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
