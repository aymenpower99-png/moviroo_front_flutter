import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../services/geocoding/geocoding_service.dart';
import '../../../../services/recent_searches/recent_searches_service.dart';
import 'location_screen_ui.dart';
import 'location_screen_location_handlers.dart';
import 'location_screen_ui_handlers.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late LocationScreenLocationHandlers _locationHandlers;
  late LocationScreenUIHandlers _uiHandlers;

  int? _selectedRider;
  int _passengerCount = 1;
  List<GeocodingPlace> _suggestions = [];
  DateTime _pickedDate = DateTime.now();
  TimeOfDay? _pickedTime;
  bool _isLoadingSuggestions = false;
  bool _isFetchingLocation = false;

  List<GeocodingPlace> _recentPickupSearches = [];
  List<GeocodingPlace> _recentDropoffSearches = [];

  // Store coordinates for navigation to RideBookingPage
  double? _pickupLat;
  double? _pickupLon;
  double? _dropoffLat;
  double? _dropoffLon;

  // Track if either input is focused for border highlight
  bool _isCardFocused = false;

  // Validation getter for confirm button
  bool get _canNavigate {
    return _fromController.text.trim().isNotEmpty &&
        _toController.text.trim().isNotEmpty &&
        _pickedTime != null &&
        _pickupLat != null &&
        _pickupLon != null &&
        _dropoffLat != null &&
        _dropoffLon != null;
  }

  // ← typed as String? so null subtitle is valid
  final _riders = <Map<String, String?>>[
    {'name': 'Me', 'subtitle': null},
    {'name': 'Youssef', 'subtitle': '+216 22 333 444'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _uiHandlers = LocationScreenUIHandlers(
      state: this,
      fromController: _fromController,
      toController: _toController,
      fromFocus: _fromFocus,
      toFocus: _toFocus,
      suggestions: _suggestions,
      recentPickupSearches: _recentPickupSearches,
      recentDropoffSearches: _recentDropoffSearches,
      riders: _riders,
      setState: setState,
      setIsCardFocused: (v) => setState(() => _isCardFocused = v),
      setSelectedRider: (v) => setState(() => _selectedRider = v),
      setPassengerCount: (v) => setState(() => _passengerCount = v),
    );

    _locationHandlers = LocationScreenLocationHandlers(
      state: this,
      fromController: _fromController,
      toController: _toController,
      fromFocus: _fromFocus,
      toFocus: _toFocus,
      suggestions: _suggestions,
      setState: setState,
      setPickupLat: (v) => setState(() => _pickupLat = v),
      setPickupLon: (v) => setState(() => _pickupLon = v),
      setDropoffLat: (v) => setState(() => _dropoffLat = v),
      setDropoffLon: (v) => setState(() => _dropoffLon = v),
      onMaybeNavigate: _maybeNavigate,
    );

    // Initialize focus state
    _updateCardFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fromFocus.requestFocus();
        _uiHandlers.loadRecentSearches();
      }
    });

    _fromController.addListener(_onQueryChanged);
    _toController.addListener(_onQueryChanged);
    _fromFocus.addListener(_onFocusChanged);
    _toFocus.addListener(_onFocusChanged);
    _fromFocus.addListener(_updateCardFocus);
    _toFocus.addListener(_updateCardFocus);
  }

  void _updateCardFocus() => _uiHandlers.updateCardFocus();
  void _onFocusChanged() => _uiHandlers.onFocusChanged();
  void _onQueryChanged() {
    _uiHandlers.onQueryChanged(
      (v) => setState(() => _isLoadingSuggestions = v),
    );
  }

  void _onSuggestionTap(GeocodingPlace place) => _locationHandlers
      .onSuggestionTap(place, _pickupLat, _pickupLon, _dropoffLat, _dropoffLon);
  void _fillSmartField(String locationName, GeocodingPlace place) =>
      _locationHandlers.fillSmartField(locationName, place);
  void _handleUseCurrentLocation() =>
      _locationHandlers.handleUseCurrentLocation(
        _pickupLat,
        _pickupLon,
        (v) => setState(() => _isFetchingLocation = v),
      );
  void _swapLocations() => _locationHandlers.swapLocations(
    _pickupLat,
    _pickupLon,
    _dropoffLat,
    _dropoffLon,
  );
  void _handleSelectOnMap() => _locationHandlers.handleSelectOnMap(
    _pickupLat,
    _pickupLon,
    _dropoffLat,
    _dropoffLon,
  );
  void _showRiderSheet() => _uiHandlers.showRiderSheet(_selectedRider);
  void _showPassengerPicker() =>
      _uiHandlers.showPassengerPicker(_passengerCount);
  void _maybeNavigate() => _locationHandlers.maybeNavigate(
    _pickupLat,
    _pickupLon,
    _dropoffLat,
    _dropoffLon,
    _toController.text.trim(),
    _fromController.text.trim(),
    _pickedDate,
    _pickedTime,
    _passengerCount,
  );

  @override
  void dispose() {
    _pulseController.dispose();
    _fromController.removeListener(_onQueryChanged);
    _toController.removeListener(_onQueryChanged);
    _fromFocus.removeListener(_onFocusChanged);
    _toFocus.removeListener(_onFocusChanged);
    _fromFocus.removeListener(_updateCardFocus);
    _toFocus.removeListener(_updateCardFocus);
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // ← translate 'Me' name at build time so it respects current locale
    _riders[0]['name'] = t.translate('me');

    final pillLabel =
        (_selectedRider != null && _selectedRider! < _riders.length)
        ? _riders[_selectedRider!]['name']!
        : t.translate('for_me');

    return LocationScreenUI(
      t: t,
      fromController: _fromController,
      toController: _toController,
      fromFocus: _fromFocus,
      toFocus: _toFocus,
      pulseAnim: _pulseAnim,
      pillLabel: pillLabel,
      passengerCount: _passengerCount,
      pickedDate: _pickedDate,
      pickedTime: _pickedTime,
      suggestions: _suggestions,
      recentPickupSearches: _recentPickupSearches,
      recentDropoffSearches: _recentDropoffSearches,
      isLoadingSuggestions: _isLoadingSuggestions,
      isFetchingLocation: _isFetchingLocation,
      isCardFocused: _isCardFocused,
      canNavigate: _canNavigate,
      onSwap: _swapLocations,
      onUseCurrentLocation: _isFetchingLocation
          ? null
          : () => _handleUseCurrentLocation(),
      onSuggestionTap: _onSuggestionTap,
      onSelectOnMap: _handleSelectOnMap,
      onDateChanged: (d) => setState(() => _pickedDate = d),
      onTimeChanged: (t) => setState(() => _pickedTime = t),
      onFillSmartField: _fillSmartField,
      onMaybeNavigate: _maybeNavigate,
      onShowRiderSheet: _showRiderSheet,
      onShowPassengerPicker: _showPassengerPicker,
      onClearPickupRecentSearches: () async {
        await RecentSearchesService.clearPickupRecentSearches();
        setState(() => _recentPickupSearches = []);
      },
      onClearDropoffRecentSearches: () async {
        await RecentSearchesService.clearDropoffRecentSearches();
        setState(() => _recentDropoffSearches = []);
      },
    );
  }
}
