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
  final List<Map<String, String?>> riders;

  final void Function(VoidCallback fn) setState;
  final void Function(bool) setIsCardFocused;
  final void Function(int?) setSelectedRider;
  final void Function(int) setPassengerCount;

  LocationScreenUIHandlers({
    required this.state,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.suggestions,
    required this.recentSearches,
    required this.riders,
    required this.setState,
    required this.setIsCardFocused,
    required this.setSelectedRider,
    required this.setPassengerCount,
  });

  void updateCardFocus() {
    final isFocused = fromFocus.hasFocus || toFocus.hasFocus;
    setIsCardFocused(isFocused);
  }

  Future<void> loadRecentSearches() async {
    final pickup = await RecentSearchesService.getPickupRecentSearches();
    if (state.mounted) {
      setState(() {
        recentSearches.clear();
        recentSearches.addAll(pickup);
      });
    }
  }

  void onFocusChanged() {
    // Always clear suggestions when focus changes
    // This ensures "Select on map" shows when the focused field is empty
    setState(() => suggestions.clear());
  }

  void onFieldFocusChanged(
    FocusNode changedFocus,
    double? pickupLat,
    double? dropoffLat,
  ) {
    // Clear unconfirmed text from the previous field when focus changes
    // Only keep values that were explicitly confirmed via autocomplete selection
    // (i.e., have coordinates set)
    if (changedFocus == fromFocus && fromFocus.hasFocus) {
      // User focused on pickup field - clear unconfirmed text in drop-off
      if (toController.text.trim().isNotEmpty && dropoffLat == null) {
        // Drop-off has text but no confirmed coordinates - clear it
        setState(() => toController.clear());
      }
    } else if (changedFocus == toFocus && toFocus.hasFocus) {
      // User focused on drop-off field - clear unconfirmed text in pickup
      if (fromController.text.trim().isNotEmpty && pickupLat == null) {
        // Pickup has text but no confirmed coordinates - clear it
        setState(() => fromController.clear());
      }
    }
  }

  void onQueryChanged(void Function(bool) setIsLoadingSuggestions) {
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

    setIsLoadingSuggestions(true);

    GeocodingService()
        .searchPlaces(query)
        .then((results) {
          if (state.mounted) {
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
