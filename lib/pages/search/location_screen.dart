import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'LocationCard.dart';
import 'nextdestinationsearch.dart';
import 'RecentSearchItem.dart';
import './DateTimeRow.dart';
import 'modal/RiderSheet.dart';
import 'modal/PassengerSheet.dart';

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
  List<SuggestionItem> _suggestions = [];
  bool _fromConfirmed = false;
  bool _toConfirmed = false;
  DateTime _pickedDate = DateTime.now();
  TimeOfDay? _pickedTime;

  final _riders = [
    {'name': 'Me', 'subtitle': 'Book this ride for yourself'},
    {'name': 'Youssef', 'subtitle': '+216 22 333 444'},
  ];

  final _recentSearches = [
    const RecentSearchItem(title: 'Sousse', subtitle: 'Sousse, Tunisia'),
    const RecentSearchItem(
      title: 'The Ferry Building',
      subtitle: '1 Ferry Building, San Francisco',
    ),
    const RecentSearchItem(title: 'Central Park', subtitle: 'New York, NY'),
  ];

  final _allPlaces = [
    const SuggestionItem(title: 'Sousse', subtitle: 'Sousse, Tunisia'),
    const SuggestionItem(title: 'Tunis Centre', subtitle: 'Tunis, Tunisia'),
    const SuggestionItem(title: 'Sfax', subtitle: 'Sfax, Tunisia'),
    const SuggestionItem(
      title: 'Monastir Airport',
      subtitle: 'Monastir, Tunisia',
    ),
    const SuggestionItem(title: 'La Marsa', subtitle: 'Tunis, Tunisia'),
    const SuggestionItem(title: 'Hammamet', subtitle: 'Nabeul, Tunisia'),
    const SuggestionItem(title: 'Carthage', subtitle: 'Tunis, Tunisia'),
    const SuggestionItem(title: 'Sidi Bou Said', subtitle: 'Tunis, Tunisia'),
    const SuggestionItem(title: 'Djerba', subtitle: 'Medenine, Tunisia'),
    const SuggestionItem(
      title: 'Tunis Carthage Airport',
      subtitle: 'Tunis, Tunisia',
    ),
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
      if (mounted) _fromFocus.requestFocus();
    });

    _fromController.addListener(_onQueryChanged);
    _toController.addListener(_onQueryChanged);
    _fromFocus.addListener(_onFocusChanged);
    _toFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
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
    if (!_fromFocus.hasFocus &&
        !_fromConfirmed &&
        _fromController.text.trim().isNotEmpty) {
      _fromController.clear();
    }
    if (!_fromFocus.hasFocus && !_toFocus.hasFocus) {
      setState(() => _suggestions = []);
    }
  }

  void _maybeNavigate() {
    final dropOff = _toController.text.trim();
    final pickUp = _fromController.text.trim();

    if (dropOff.isNotEmpty && pickUp.isNotEmpty && _pickedTime != null) {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/vehicle_selection_page',
          arguments: {
            'pickUp': pickUp,
            'dropOff': dropOff,
            'date': _pickedDate,
            'time': _pickedTime,
            'passengerCount': _passengerCount,
          },
        );
      });
    }
  }

  void _onQueryChanged() {
    if (!_fromFocus.hasFocus && !_toFocus.hasFocus) {
      setState(() => _suggestions = []);
      return;
    }

    final query = _toFocus.hasFocus
        ? _toController.text.trim()
        : _fromController.text.trim();
    if (!_toFocus.hasFocus) _fromConfirmed = false;

    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final filtered = _allPlaces
        .where(
          (p) =>
              p.title.toLowerCase().contains(query.toLowerCase()) ||
              (p.subtitle?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .take(4)
        .toList();

    setState(() => _suggestions = filtered);
  }

  void _onSuggestionTap(SuggestionItem item) {
    if (_toFocus.hasFocus) {
      _toController.text = item.title;
      _toConfirmed = true;
      setState(() => _suggestions = []);
      _maybeNavigate();
    } else if (_fromFocus.hasFocus) {
      _fromController.text = item.title;
      _fromConfirmed = true;
      setState(() => _suggestions = []);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _toFocus.requestFocus();
      });
    } else {
      _fillSmartField(item.title);
    }
  }

  void _fillSmartField(String locationName) {
    final fromEmpty = _fromController.text.trim().isEmpty;
    setState(() => _suggestions = []);

    if (fromEmpty) {
      _fromController.text = locationName;
      _fromConfirmed = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _toFocus.requestFocus();
      });
    } else {
      _toController.text = locationName;
      _toConfirmed = true;
      _maybeNavigate();
    }
  }

  void _swapLocations() {
    final from = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = from;
    _fromConfirmed = _fromController.text.trim().isNotEmpty;
    _toConfirmed = _toController.text.trim().isNotEmpty;
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
    final pillLabel =
        (_selectedRider != null && _selectedRider! < _riders.length)
        ? _riders[_selectedRider!]['name']!
        : 'For me';

    final showRecent =
        _suggestions.isEmpty &&
        _recentSearches.isNotEmpty &&
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
                    'Plan your ride',
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
                        // AFTER
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
                      label: '$_passengerCount',
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
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                      onUseCurrentLocation: () {},
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
                      onSelectOnMap: () {},
                      onSavedPlaces: () {},
                    ),
                    if (showRecent) ...[
                      const SizedBox(height: 2),
                      ..._recentSearches.map(
                        (item) => RecentSearchTile(
                          item: item,
                          onTap: () => _fillSmartField(item.title),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _recentSearches.clear()),
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
                                'Clear',
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
          ],
        ),
      ),
    );
  }
}

// Extracted pill widget to reduce duplication
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
          // AFTER
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
