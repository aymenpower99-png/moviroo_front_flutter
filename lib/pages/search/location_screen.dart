import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'LocationCard.dart';
import 'nextdestinationsearch.dart';
import 'RecentSearchItem.dart';
import './DateTimeRow.dart';
import 'modal/RiderSheet.dart';
import 'modal/PassengerSheet.dart';
import '../../../services/mapbox_place.dart';
import '../../../services/mapbox_service.dart';
import '../../../services/recent_searches_service.dart';
import '../../../services/gps_service.dart';
import 'map_location_picker.dart';
import 'dart:async';

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

  int? _selectedRider;
  int _passengerCount = 1;
  List<MapboxPlace> _suggestions = [];
  DateTime _pickedDate = DateTime.now();
  TimeOfDay? _pickedTime;
  bool _isLoadingSuggestions = false;
  bool _isFetchingLocation = false;
  Timer? _debounce; // ← ADD HERE

  List<MapboxPlace> _recentPickupSearches = [];
  List<MapboxPlace> _recentDropoffSearches = [];

  // Store coordinates for navigation to RideBookingPage
  double? _pickupLat;
  double? _pickupLon;
  double? _dropoffLat;
  double? _dropoffLon;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fromFocus.requestFocus();
        _loadRecentSearches();
      }
    });

    _fromController.addListener(_onQueryChanged);
    _toController.addListener(_onQueryChanged);
    _fromFocus.addListener(_onFocusChanged);
    _toFocus.addListener(_onFocusChanged);
  }

  Future<void> _loadRecentSearches() async {
    final pickup = await RecentSearchesService.getPickupRecentSearches();
    final dropoff = await RecentSearchesService.getDropoffRecentSearches();
    if (mounted) {
      setState(() {
        _recentPickupSearches = pickup;
        _recentDropoffSearches = dropoff;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // ← ADD HERE
    _pulseController.dispose();
    _fromController.removeListener(_onQueryChanged);
    _toController.removeListener(_onQueryChanged);
    _fromFocus.removeListener(_onFocusChanged);
    _toFocus.removeListener(_onFocusChanged);
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Only clear suggestions when both fields lose focus
    // Don't clear the input text automatically - let the user control it
    if (!_fromFocus.hasFocus && !_toFocus.hasFocus) {
      setState(() => _suggestions = []);
    }
  }

  void _maybeNavigate() {
    final dropOff = _toController.text.trim();
    final pickUp = _fromController.text.trim();

    if (dropOff.isNotEmpty &&
        pickUp.isNotEmpty &&
        _pickedTime != null &&
        _pickupLat != null &&
        _pickupLon != null &&
        _dropoffLat != null &&
        _dropoffLon != null) {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/ride_booking_page',
          arguments: {
            'pickupLat': _pickupLat,
            'pickupLon': _pickupLon,
            'pickupAddress': pickUp,
            'dropoffLat': _dropoffLat,
            'dropoffLon': _dropoffLon,
            'dropoffAddress': dropOff,
            'date': _pickedDate,
            'time': _pickedTime,
            'passengerCount': _passengerCount,
          },
        );
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();

    if (!_fromFocus.hasFocus && !_toFocus.hasFocus) {
      setState(() => _suggestions = []);
      return;
    }

    final query = _toFocus.hasFocus
        ? _toController.text.trim()
        : _fromController.text.trim();

    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoadingSuggestions = true);
      try {
        final results = await MapboxService.searchPlaces(query);
        if (mounted) setState(() => _suggestions = results);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        if (mounted) setState(() => _isLoadingSuggestions = false);
      }
    });
  }

  void _onSuggestionTap(MapboxPlace place) async {
    if (_toFocus.hasFocus) {
      _toController.text = place.placeName;
      setState(() {
        _suggestions = [];
        _dropoffLat = place.latitude;
        _dropoffLon = place.longitude;
      });
      await RecentSearchesService.addDropoffRecentSearch(place);
      _maybeNavigate();
    } else if (_fromFocus.hasFocus) {
      _fromController.text = place.placeName;
      setState(() {
        _suggestions = [];
        _pickupLat = place.latitude;
        _pickupLon = place.longitude;
      });
      await RecentSearchesService.addPickupRecentSearch(place);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _toFocus.requestFocus();
      });
    } else {
      _fillSmartField(place.placeName, place);
    }
  }

  void _fillSmartField(String locationName, MapboxPlace place) async {
    final fromEmpty = _fromController.text.trim().isEmpty;
    setState(() => _suggestions = []);

    if (fromEmpty) {
      _fromController.text = locationName;
      setState(() {
        _pickupLat = place.latitude;
        _pickupLon = place.longitude;
      });
      await RecentSearchesService.addPickupRecentSearch(place);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _toFocus.requestFocus();
      });
    } else {
      _toController.text = locationName;
      setState(() {
        _dropoffLat = place.latitude;
        _dropoffLon = place.longitude;
      });
      await RecentSearchesService.addDropoffRecentSearch(place);
      _maybeNavigate();
    }
  }

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final place = await GpsService.getCurrentLocationWithAddress();
      if (place != null && mounted) {
        _fromController.text = place.placeName;
        setState(() {
          _pickupLat = place.latitude;
          _pickupLon = place.longitude;
        });
        await RecentSearchesService.addPickupRecentSearch(place);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _toFocus.requestFocus();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to get current location'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission denied or unavailable'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _swapLocations() {
    final from = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = from;
  }

  Future<void> _handleSelectOnMap() async {
    // Decide which field we are filling. Pickup is filled first if empty,
    // otherwise we fill drop-off.
    final fillingPickup = _fromController.text.trim().isEmpty;
    final target = fillingPickup ? _fromController : _toController;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: fillingPickup
              ? 'Set your pickup spot'
              : 'Set your drop-off spot',
          subtitle: 'Drag map to move pin',
          confirmLabel: fillingPickup ? 'Confirm pickup' : 'Confirm drop-off',
          initialAddress: target.text,
        ),
      ),
    );

    if (result != null && mounted) {
      final address = (result['address'] as String?)?.trim() ?? '';
      final lat = result['latitude'] as double?;
      final lon = result['longitude'] as double?;
      if (address.isNotEmpty) {
        setState(() => target.text = address);
        if (fillingPickup) {
          setState(() {
            _pickupLat = lat;
            _pickupLon = lon;
          });
        } else {
          setState(() {
            _dropoffLat = lat;
            _dropoffLon = lon;
          });
        }
        // If we just filled pickup, move focus to drop-off so the user can
        // immediately continue the flow.
        if (fillingPickup) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _toFocus.requestFocus();
          });
        }
      }
    }
  }

  Future<void> _showRiderSheet() async {
    _fromFocus.unfocus();
    _toFocus.unfocus();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final selected = await RiderSheet.show(
      context,
      riders: _riders,
      initialSelected: _selectedRider,
      onRidersChanged: (updated) => setState(() {
        _riders
          ..clear()
          ..addAll(updated);
      }),
    );

    _fromFocus.unfocus();
    _toFocus.unfocus();
    if (selected != null && mounted) {
      setState(() => _selectedRider = selected);
    }
  }

  Future<void> _showPassengerPicker() async {
    _fromFocus.unfocus();
    _toFocus.unfocus();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final selected = await PassengerSheet.show(
      context,
      initialCount: _passengerCount,
    );

    _fromFocus.unfocus();
    _toFocus.unfocus();
    if (selected != null && mounted) {
      setState(() => _passengerCount = selected);
    }
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

    final isPickupFocused = _fromFocus.hasFocus;
    final currentRecentSearches = isPickupFocused
        ? _recentPickupSearches
        : _recentDropoffSearches;

    final showRecent =
        _suggestions.isEmpty &&
        currentRecentSearches.isNotEmpty &&
        !(_fromFocus.hasFocus && _fromController.text.trim().isNotEmpty) &&
        !(_toFocus.hasFocus && _toController.text.trim().isNotEmpty);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    t.translate('plan_your_ride'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.text(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Rider & Passenger pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: Icons.person_outline_rounded,
                      label: pillLabel,
                      onTap: _showRiderSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      icon: Icons.people_outline_rounded,
                      label: '$_passengerCount ${t.translate('passengers')}',
                      onTap: _showPassengerPicker,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationCard(
                      fromController: _fromController,
                      toController: _toController,
                      fromFocus: _fromFocus,
                      toFocus: _toFocus,
                      pulseAnim: _pulseAnim,
                      onSwap: _swapLocations,
                      onUseCurrentLocation: _isFetchingLocation
                          ? null
                          : () => _handleUseCurrentLocation(),
                      isFetchingLocation: _isFetchingLocation,
                    ),
                    const SizedBox(height: 10),
                    DateTimeRow(
                      initialDate: _pickedDate,
                      onDateChanged: (d) => setState(() => _pickedDate = d),
                      onTimeChanged: (t) => setState(() => _pickedTime = t),
                    ),
                    const SizedBox(height: 14),
                    NextDestinationSearch(
                      suggestions: _suggestions,
                      onSuggestionTap: _onSuggestionTap,
                      onSelectOnMap: _handleSelectOnMap,
                    ),
                    if (showRecent) ...[
                      const SizedBox(height: 2),
                      ...(_fromFocus.hasFocus
                              ? _recentPickupSearches
                              : _recentDropoffSearches)
                          .map(
                            (place) => RecentSearchTile(
                              item: RecentSearchItem(
                                title: place.placeName,
                                subtitle: place.fullAddress,
                                categoryIcon: place.categoryIcon,
                              ),
                              onTap: () =>
                                  _fillSmartField(place.placeName, place),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () async {
                            if (_fromFocus.hasFocus) {
                              await RecentSearchesService.clearPickupRecentSearches();
                              setState(() => _recentPickupSearches = []);
                            } else {
                              await RecentSearchesService.clearDropoffRecentSearches();
                              setState(() => _recentDropoffSearches = []);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: AppColors.subtext(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.translate('clear'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Confirm button (only shows when both fields are filled) ──
            if (_fromController.text.trim().isNotEmpty &&
                _toController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _maybeNavigate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      t.translate('confirm'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Pill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            Icon(icon, size: 17, color: AppColors.primaryPurple),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }
}
