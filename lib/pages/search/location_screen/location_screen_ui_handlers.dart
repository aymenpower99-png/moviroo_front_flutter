import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../services/geocoding/geocoding_service.dart';
import '../../../../services/recent_searches/recent_searches_service.dart';
import '../modal/RiderSheet.dart';
import '../modal/PassengerSheet.dart';

/// UI-related handler methods for LocationScreen
class LocationScreenUIHandlers {
  final State state;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final List<GeocodingPlace> suggestions;
  final List<GeocodingPlace> recentSearches;
  final List<GeocodingPlace> dropoffRecentSearches;
  final List<Map<String, String?>> riders;

  final void Function(VoidCallback fn) setState;
  final void Function(bool) setIsCardFocused;
  final void Function(int?) setSelectedRider;
  final void Function(int) setPassengerCount;

  Timer? _debounceTimer;

  LocationScreenUIHandlers({
    required this.state,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.suggestions,
    required this.recentSearches,
    required this.dropoffRecentSearches,
    required this.riders,
    required this.setState,
    required this.setIsCardFocused,
    required this.setSelectedRider,
    required this.setPassengerCount,
  });

  void dispose() {
    _debounceTimer?.cancel();
  }

  void updateCardFocus() {
    final isFocused = fromFocus.hasFocus || toFocus.hasFocus;
    setIsCardFocused(isFocused);
  }

  Future<void> loadRecentSearches() async {
    if (!state.mounted) return;

    if (toFocus.hasFocus) {
      final dropoff = await RecentSearchesService.getDropoffRecentSearches();
      if (state.mounted) {
        setState(() {
          dropoffRecentSearches.clear();
          dropoffRecentSearches.addAll(dropoff);
        });
      }
    } else {
      final pickup = await RecentSearchesService.getPickupRecentSearches();
      if (state.mounted) {
        setState(() {
          recentSearches.clear();
          recentSearches.addAll(pickup);
        });
      }
    }
  }

  void onFocusChanged() {
    // Only clear suggestions if the focused field is empty.
    // If the user already typed something, keep suggestions visible.
    final query = toFocus.hasFocus
        ? toController.text.trim()
        : fromController.text.trim();
    if (query.isEmpty) {
      setState(() => suggestions.clear());
    }
  }

  void onFieldFocusChanged(
    FocusNode changedFocus,
    double? pickupLat,
    double? pickupLon,
    double? dropoffLat,
    void Function(bool) setIsLoadingSuggestions,
  ) {
    // NOTE: We intentionally do NOT clear unconfirmed text when switching focus.
    // Users often type a partial address, switch fields to check something,
    // and come back. Auto-clearing destroys their input.
    // Only confirmed selections (with coordinates) are kept as-is.
  }

  void onQueryChanged(
    void Function(bool) setIsLoadingSuggestions, {
    double? proximityLat,
    double? proximityLon,
    String? language,
  }) {
    if (!fromFocus.hasFocus && !toFocus.hasFocus) {
      setState(() => suggestions.clear());
      return;
    }

    final query = toFocus.hasFocus
        ? toController.text.trim()
        : fromController.text.trim();

    if (query.isEmpty) {
      setState(() => suggestions.clear());
      return;
    }

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Debounce: wait 350ms after the user stops typing before calling backend
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!state.mounted) return;

      // Re-check current query after debounce
      final currentQuery = toFocus.hasFocus
          ? toController.text.trim()
          : fromController.text.trim();
      if (currentQuery != query) return;

      setIsLoadingSuggestions(true);

      GeocodingService()
          .searchPlaces(
            query,
            proximityLat: proximityLat,
            proximityLon: proximityLon,
            language: language,
          )
          .then((results) {
            if (state.mounted) {
              // Discard stale results if focus moved or text changed since query started
              final latestQuery = toFocus.hasFocus
                  ? toController.text.trim()
                  : fromController.text.trim();
              if (latestQuery != query) return;

              setState(() {
                suggestions.clear();
                suggestions.addAll(results);
              });
            }
          })
          .catchError((e) {
            debugPrint('Search error: $e');
          })
          .whenComplete(() {
            if (state.mounted) setIsLoadingSuggestions(false);
          });
    });
  }

  Future<void> showRiderSheet(int? selectedRider) async {
    fromFocus.unfocus();
    toFocus.unfocus();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!state.mounted) return;

    final selected = await RiderSheet.show(
      state.context,
      riders: riders,
      initialSelected: selectedRider,
      onRidersChanged: (updated) => setState(() {
        riders.clear();
        riders.addAll(updated);
      }),
    );

    fromFocus.unfocus();
    toFocus.unfocus();
    if (selected != null && state.mounted) {
      setState(() => setSelectedRider(selected));
    }
  }

  Future<void> showPassengerPicker(int passengerCount) async {
    fromFocus.unfocus();
    toFocus.unfocus();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!state.mounted) return;

    final selected = await PassengerSheet.show(
      state.context,
      initialCount: passengerCount,
    );

    fromFocus.unfocus();
    toFocus.unfocus();
    if (selected != null && state.mounted) {
      setState(() => setPassengerCount(selected));
    }
  }
}
