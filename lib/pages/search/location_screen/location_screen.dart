import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../services/geocoding/geocoding_service.dart';
import '../../../../services/recent_searches/recent_searches_service.dart';
import 'location_screen_ui.dart';
import 'location_screen_location_handlers.dart';
import 'location_screen_ui_handlers.dart';

class LocationScreen extends StatefulWidget {
  final Map<String, dynamic>? voiceArgs;

  const LocationScreen({super.key, this.voiceArgs});

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
  final List<GeocodingPlace> _suggestions = [];
  List<GeocodingPlace> _nearbyPlaces = [];
  DateTime _pickedDate = DateTime.now();
  TimeOfDay? _pickedTime;
  bool _isLoadingSuggestions = false;
  bool _isLoadingNearbyPlaces = false;
  bool _isFetchingLocation = false;

  List<GeocodingPlace> _recentSearches = [];
  List<GeocodingPlace> _dropoffRecentSearches = [];

  // Store coordinates for navigation to RideBookingPage
  double? _pickupLat;
  double? _pickupLon;
  double? _dropoffLat;
  double? _dropoffLon;

  // Cache key for nearby places to avoid redundant backend calls
  String? _nearbyPlacesCacheKey;

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
      recentSearches: _recentSearches,
      dropoffRecentSearches: _dropoffRecentSearches,
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

    // Pre-fill from voice assistant results if available
    _applyVoiceArgs();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (widget.voiceArgs == null) _fromFocus.requestFocus();
        await _uiHandlers.loadRecentSearches();
        // If drop-off is already focused and pickup has coords, load nearby
        if (_toFocus.hasFocus && _pickupLat != null && _pickupLon != null) {
          _fetchNearbyPlacesIfNeeded();
        }
      }
    });

    _fromController.addListener(_onQueryChanged);
    _toController.addListener(_onQueryChanged);
    _fromFocus.addListener(_onFocusChanged);
    _toFocus.addListener(_onFocusChanged);
    _fromFocus.addListener(_onFromFieldFocusChanged);
    _toFocus.addListener(_onToFieldFocusChanged);
    _fromFocus.addListener(_updateCardFocus);
    _toFocus.addListener(_updateCardFocus);
  }

  void _applyVoiceArgs() {
    final args = widget.voiceArgs;
    if (args == null) return;

    final useCurrentLoc = args['useCurrentLocation'] == true;
    final pickupAddr = args['pickupAddress'] as String?;
    final dropoffAddr = args['dropoffAddress'] as String?;

    if (useCurrentLoc || pickupAddr == 'current_location') {
      // Show a human-readable label and auto-resolve GPS coordinates
      _fromController.text = 'My Current Location';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleUseCurrentLocation();
      });
    } else if (pickupAddr != null && pickupAddr.isNotEmpty) {
      _fromController.text = pickupAddr;
    }

    if (dropoffAddr != null && dropoffAddr.isNotEmpty) {
      _toController.text = dropoffAddr;
    }

    final pLat = args['pickupLat'] as double?;
    final pLon = args['pickupLon'] as double?;
    final dLat = args['dropoffLat'] as double?;
    final dLon = args['dropoffLon'] as double?;
    if (pLat != null) _pickupLat = pLat;
    if (pLon != null) _pickupLon = pLon;
    if (dLat != null) _dropoffLat = dLat;
    if (dLon != null) _dropoffLon = dLon;

    if (args['date'] is DateTime) _pickedDate = args['date'] as DateTime;
    if (args['time'] is TimeOfDay) _pickedTime = args['time'] as TimeOfDay;
  }

  void _updateCardFocus() => _uiHandlers.updateCardFocus();
  void _onFocusChanged() => _uiHandlers.onFocusChanged();

  void _onFromFieldFocusChanged() {
    _uiHandlers.loadRecentSearches();
  }

  void _onToFieldFocusChanged() {
    _uiHandlers.loadRecentSearches();
    // Fetch nearby places when focus lands on drop-off and pickup is confirmed
    if (_toFocus.hasFocus && _pickupLat != null && _pickupLon != null) {
      _fetchNearbyPlacesIfNeeded();
    }
  }
  void _onQueryChanged() {
    final locale = Localizations.localeOf(context).languageCode;
    _uiHandlers.onQueryChanged(
      (v) => setState(() => _isLoadingSuggestions = v),
      proximityLat: _pickupLat,
      proximityLon: _pickupLon,
      language: locale,
    );

    // Keep nearby places refreshed while user is typing drop-off
    if (_toFocus.hasFocus && _pickupLat != null && _pickupLon != null) {
      _fetchNearbyPlacesIfNeeded();
    }
  }

  Future<void> _fetchNearbyPlacesIfNeeded() async {
    // Fetch nearby places around the confirmed pickup location.
    // The caller must ensure drop-off is focused and pickup has valid coords.
    if (_pickupLat == null || _pickupLon == null) return;
    if (_pickupLat == 0.0 && _pickupLon == 0.0) return;
    if (_pickupLat!.isNaN || _pickupLon!.isNaN) return;

    // Cache key based on pickup coordinates (rounded to 4 decimals)
    final cacheKey =
        '${_pickupLat!.toStringAsFixed(4)},${_pickupLon!.toStringAsFixed(4)}';
    if (_nearbyPlacesCacheKey == cacheKey && _nearbyPlaces.isNotEmpty) return;

    setState(() => _isLoadingNearbyPlaces = true);

    try {
      final nearby = await GeocodingService().getNearbyPlaces(
        _pickupLat!,
        _pickupLon!,
      );

      if (mounted) {
        setState(() {
          _nearbyPlaces = nearby;
          _isLoadingNearbyPlaces = false;
          _nearbyPlacesCacheKey = cacheKey;
        });
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
      if (mounted) {
        setState(() => _isLoadingNearbyPlaces = false);
      }
    }
  }

  void _onSuggestionTap(GeocodingPlace place) async {
    await _locationHandlers.onSuggestionTap(
      place, _pickupLat, _pickupLon, _dropoffLat, _dropoffLon,
    );
    // After pickup is confirmed and focus moves to drop-off, explicitly
    // trigger nearby places with a short delay so focus has settled.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _toFocus.hasFocus && _pickupLat != null) {
        _fetchNearbyPlacesIfNeeded();
      }
    });
  }
  void _fillSmartField(String locationName, GeocodingPlace place) =>
      _locationHandlers.fillSmartField(locationName, place);
  void _handleUseCurrentLocation() {
    final locale = Localizations.localeOf(context).languageCode;
    _locationHandlers.handleUseCurrentLocation(
      _pickupLat,
      _pickupLon,
      (v) => setState(() => _isFetchingLocation = v),
      language: locale,
    );
  }
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
    _uiHandlers.dispose();
    _pulseController.dispose();
    _fromController.removeListener(_onQueryChanged);
    _toController.removeListener(_onQueryChanged);
    _fromFocus.removeListener(_onFocusChanged);
    _toFocus.removeListener(_onFocusChanged);
    _fromFocus.removeListener(_onFromFieldFocusChanged);
    _toFocus.removeListener(_onToFieldFocusChanged);
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
      nearbyPlaces: _nearbyPlaces,
      recentSearches: _recentSearches,
      dropoffRecentSearches: _dropoffRecentSearches,
      isLoadingSuggestions: _isLoadingSuggestions,
      isLoadingNearbyPlaces: _isLoadingNearbyPlaces,
      isFetchingLocation: _isFetchingLocation,
      isCardFocused: _isCardFocused,
      canNavigate: _canNavigate,
      pickupLat: _pickupLat,
      pickupLon: _pickupLon,
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
      onClearRecentSearches: () async {
        if (_toFocus.hasFocus) {
          await RecentSearchesService.clearDropoffRecentSearches();
          setState(() => _dropoffRecentSearches = []);
        } else {
          await RecentSearchesService.clearPickupRecentSearches();
          setState(() => _recentSearches = []);
        }
      },
    );
  }
}
