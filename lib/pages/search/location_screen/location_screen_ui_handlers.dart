import 'package:flutter/material.dart';
import '../../../../services/mapbox/mapbox_place.dart';
import '../../../../services/mapbox/mapbox_service.dart';
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
  final List<MapboxPlace> suggestions;
  final List<MapboxPlace> recentPickupSearches;
  final List<MapboxPlace> recentDropoffSearches;
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
    required this.recentPickupSearches,
    required this.recentDropoffSearches,
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
    final dropoff = await RecentSearchesService.getDropoffRecentSearches();
    if (state.mounted) {
      setState(() {
        recentPickupSearches.clear();
        recentPickupSearches.addAll(pickup);
        recentDropoffSearches.clear();
        recentDropoffSearches.addAll(dropoff);
      });
    }
  }

  void onFocusChanged() {
    if (!fromFocus.hasFocus && !toFocus.hasFocus) {
      setState(() => suggestions.clear());
    }
  }

  void onQueryChanged(
    bool pickupFrozen,
    bool dropoffFrozen,
    void Function(bool) setIsLoadingSuggestions,
  ) {
    // Remove frozen state blocking - allow search even when frozen
    // User might be editing the text after selecting a suggestion
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

    MapboxService.searchPlaces(query)
        .then((results) {
          if (state.mounted)
            setState(() {
              suggestions.clear();
              suggestions.addAll(results);
            });
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
