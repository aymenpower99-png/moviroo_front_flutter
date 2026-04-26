import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../../../theme/app_colors.dart';
import '../../../../models/vehicle_pricing_response.dart';
import '../../../../services/vehicle_pricing/vehicle_pricing_service.dart';
import '../../../../services/mapbox/mapbox_service.dart';
import '../../../../routing/router.dart';
import '../_CarCard.dart';
import 'map_manager.dart';
import 'ride_booking_map_view.dart';
import 'ride_booking_sheet.dart';

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

class _RideBookingPageState extends State<RideBookingPage> with RouteAware {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    // Another route was pushed on top of this one (navigated away).
    // Stop the map animation to prevent background processing.
    debugPrint('[RideBookingPage] didPushNext: pausing map animation');
    _mapManager?.pauseAnimation();
  }

  @override
  void didPopNext() {
    // The route on top of this one was popped (returned to this page).
    // Resume the map animation.
    debugPrint('[RideBookingPage] didPopNext: resuming map animation');
    _mapManager?.resumeAnimation();
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

  void _handleConfirm() {
    if (_pricingResponse == null || _pricingResponse!.vehicleClasses.isEmpty) {
      return;
    }

    final selectedVehicle = _pricingResponse!.vehicleClasses[_selectedCarIndex];

    AppRouter.push(
      context,
      AppRouter.booking,
      args: {
        'selectedVehicle': selectedVehicle,
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'pickupLat': widget.pickupLat,
        'pickupLon': widget.pickupLon,
        'dropoffLat': widget.dropoffLat,
        'dropoffLon': widget.dropoffLon,
        'scheduledDate': widget.pickedDate,
        'scheduledTime': widget.pickedTime,
      },
    );
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _mapManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cars = _filteredCars;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Map + back button + anchored location cards ─────────────────
          Positioned.fill(
            child: RideBookingMapView(
              isDark: isDark,
              pickupLat: widget.pickupLat,
              pickupLon: widget.pickupLon,
              dropoffLat: widget.dropoffLat,
              dropoffLon: widget.dropoffLon,
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
              onCameraChanged: _onCameraChanged,
              pickupScreen: _pickupScreen,
              dropoffScreen: _dropoffScreen,
              screenWidth: screenWidth,
              isLoadingAddresses: _isLoadingAddresses,
              pickupAddress: _pickupAddress,
              dropoffAddress: _dropoffAddress,
              pickupCity: _pickupCity,
              pickupCountry: _pickupCountry,
              dropoffCity: _dropoffCity,
              dropoffCountry: _dropoffCountry,
            ),
          ),

          // ── Bottom sheet (drag handle + cards + sticky confirm) ─────────
          RideBookingSheet(
            isLoadingPrices: _isLoadingPrices,
            cars: cars,
            selectedCarIndex: _selectedCarIndex,
            onCarSelected: (index) => setState(() => _selectedCarIndex = index),
            onConfirm: _handleConfirm,
          ),
        ],
      ),
    );
  }
}
