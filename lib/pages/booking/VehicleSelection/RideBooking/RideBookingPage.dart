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
  final DateTime? pickedDate;
  final TimeOfDay? pickedTime;

  const RideBookingPage({
    super.key,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickedDate,
    this.pickedTime,
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
  // Manual sheet drag state
  double _sheetHeight = 0.35; // Initial height (fraction of screen)
  double _dragStartY = 0.0;
  double _dragStartHeight = 0.35;

  Offset? _pickupScreen;
  Offset? _dropoffScreen;

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress ?? '';
    _dropoffAddress = widget.dropoffAddress ?? '';
    if (_pickupAddress.isNotEmpty && _dropoffAddress.isNotEmpty) {
      _isLoadingAddresses = false;
    }
    _loadVehiclePrices();
    _loadAddressDetails();
  }

  Future<void> _loadAddressDetails() async {
    try {
      final results = await Future.wait([
        MapboxService.reverseGeocode(widget.pickupLat, widget.pickupLon),
        MapboxService.reverseGeocode(widget.dropoffLat, widget.dropoffLon),
      ]);
      final pickupPlace = results[0];
      final dropoffPlace = results[1];
      if (mounted) {
        setState(() {
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

    String? bookingDt;
    if (widget.pickedDate != null && widget.pickedTime != null) {
      final combinedDateTime = DateTime(
        widget.pickedDate!.year,
        widget.pickedDate!.month,
        widget.pickedDate!.day,
        widget.pickedTime!.hour,
        widget.pickedTime!.minute,
      );
      bookingDt = combinedDateTime.toIso8601String();
    }

    final response = await service.getVehiclePrices(
      pickupLat: widget.pickupLat,
      pickupLon: widget.pickupLon,
      dropoffLat: widget.dropoffLat,
      dropoffLon: widget.dropoffLon,
      bookingDt: bookingDt,
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
      context: context,
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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final t = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Sheet height calculation ────────────────────────────────────────────
    // Calculate the height needed to fit 1 card + header + confirm bar.
    // This is used as the initial collapsed height.
    final reservePx =
        _headerHeightPx + _sliverTopPadPx + _confirmBarHeightPx + bottomPad;
    final oneCardSize = (reservePx + _cardHeightPx) / screenHeight;

    // Initialize sheet height if not already set (first build)
    if (_sheetHeight == 0.35) {
      _sheetHeight = oneCardSize.clamp(0.25, 0.85);
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Mapbox map (full screen) ──────────────────────────────────────
          Positioned.fill(
            child: mbx.MapWidget(
              styleUri: isDark
                  ? mbx.MapboxStyles.DARK
                  : mbx.MapboxStyles.MAPBOX_STREETS,
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
                zoom: 14.0,
                bearing: 0.0,
                pitch: 0.0,
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: const BackButtonWidget(),
          ),

          // ── Pickup location card ──────────────────────────────────────────
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

          // ── Drop-off location card ────────────────────────────────────────
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

          // ── Bottom sheet (manual implementation) ────────────────────────────
          //
          // Manual Positioned + GestureDetector implementation to avoid
          // "Each child must be laid out exactly once" crashes from
          // DraggableScrollableSheet. The sheet is positioned at the bottom
          // and its height is controlled by drag gestures on the pill.
          //
          Positioned(
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
                final newHeight = (_dragStartHeight + deltaHeight).clamp(
                  0.25,
                  0.85,
                );
                setState(() {
                  _sheetHeight = newHeight;
                });
              },
              child: Container(
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
                child: _isLoadingPrices
                    ? const Column(
                        children: [
                          SheetHeader(),
                          Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      )
                    : _filteredCars.isEmpty
                    ? Column(
                        children: [
                          const SheetHeader(),
                          Expanded(
                            child: Center(
                              child: Text(
                                t.translate('no_vehicles_available'),
                                style: AppTextStyles.bodyMedium(context),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const SheetHeader(),
                          Flexible(
                            child: ClipRect(
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  for (
                                    int index = 0;
                                    index < _filteredCars.length;
                                    index++
                                  )
                                    CarCard(
                                      car: _filteredCars[index],
                                      isSelected: _selectedCarIndex == index,
                                      onTap: () => setState(
                                        () => _selectedCarIndex = index,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedCar != null)
                            ConfirmBar(
                              car: _selectedCar!,
                              bottomPad: bottomPad,
                              onConfirm: () {
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
