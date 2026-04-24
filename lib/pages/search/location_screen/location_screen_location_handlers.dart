import 'package:flutter/material.dart';
import '../../../../services/mapbox/mapbox_place.dart';
import '../../../../services/mapbox/mapbox_service.dart';
import '../../../../services/recent_searches/recent_searches_service.dart';
import '../../../../services/gps/gps_service.dart';
import '../map_location_picker/map_location_picker.dart';

/// Location-related handler methods for LocationScreen
class LocationScreenLocationHandlers {
  final State state;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final List<MapboxPlace> suggestions;
  
  final void Function(VoidCallback fn) setState;
  final void Function(double?) setPickupLat;
  final void Function(double?) setPickupLon;
  final void Function(double?) setDropoffLat;
  final void Function(double?) setDropoffLon;
  final void Function(bool) setPickupFrozen;
  final void Function(bool) setDropoffFrozen;
  final VoidCallback onMaybeNavigate;

  LocationScreenLocationHandlers({
    required this.state,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.suggestions,
    required this.setState,
    required this.setPickupLat,
    required this.setPickupLon,
    required this.setDropoffLat,
    required this.setDropoffLon,
    required this.setPickupFrozen,
    required this.setDropoffFrozen,
    required this.onMaybeNavigate,
  });

  Future<void> onSuggestionTap(MapboxPlace place, double? pickupLat, double? pickupLon, double? dropoffLat, double? dropoffLon, bool pickupFrozen, bool dropoffFrozen) async {
    if (toFocus.hasFocus) {
      toController.text = place.placeName;
      setState(() {
        suggestions.clear();
        setDropoffLat(place.latitude);
        setDropoffLon(place.longitude);
        setDropoffFrozen(true);
      });
      await RecentSearchesService.addDropoffRecentSearch(place);
      onMaybeNavigate();
    } else if (fromFocus.hasFocus) {
      fromController.text = place.placeName;
      setState(() {
        suggestions.clear();
        setPickupLat(place.latitude);
        setPickupLon(place.longitude);
        setPickupFrozen(true);
      });
      await RecentSearchesService.addPickupRecentSearch(place);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (state.mounted) toFocus.requestFocus();
      });
    }
  }

  void fillSmartField(String locationName, MapboxPlace place) async {
    final fromEmpty = fromController.text.trim().isEmpty;
    setState(() => suggestions.clear());

    if (fromEmpty) {
      fromController.text = locationName;
      setState(() {
        setPickupLat(place.latitude);
        setPickupLon(place.longitude);
        setPickupFrozen(true);
      });
      await RecentSearchesService.addPickupRecentSearch(place);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (state.mounted) toFocus.requestFocus();
      });
    } else {
      toController.text = locationName;
      setState(() {
        setDropoffLat(place.latitude);
        setDropoffLon(place.longitude);
        setDropoffFrozen(true);
      });
      await RecentSearchesService.addDropoffRecentSearch(place);
      onMaybeNavigate();
    }
  }

  Future<void> handleUseCurrentLocation(double? pickupLat, double? pickupLon, bool pickupFrozen, void Function(bool) setIsFetchingLocation) async {
    setIsFetchingLocation(true);

    try {
      final place = await GpsService.getCurrentLocationWithAddress();
      if (place != null && state.mounted) {
        fromController.text = place.placeName;
        setState(() {
          setPickupLat(place.latitude);
          setPickupLon(place.longitude);
          setPickupFrozen(true);
        });
        await RecentSearchesService.addPickupRecentSearch(place);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (state.mounted) toFocus.requestFocus();
        });
      } else {
        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            SnackBar(
              content: Text('Unable to get current location'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          SnackBar(
            content: Text('Location permission denied or unavailable'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (state.mounted) {
        setIsFetchingLocation(false);
      }
    }
  }

  void swapLocations(double? pickupLat, double? pickupLon, double? dropoffLat, double? dropoffLon) {
    final fromText = fromController.text;
    final toText = toController.text;
    final tmpLat = pickupLat;
    final tmpLon = pickupLon;

    fromController.text = toText;
    toController.text = fromText;

    setState(() {
      setPickupLat(dropoffLat);
      setPickupLon(dropoffLon);
      setDropoffLat(tmpLat);
      setDropoffLon(tmpLon);
    });
  }

  Future<void> handleSelectOnMap(double? pickupLat, double? pickupLon, double? dropoffLat, double? dropoffLon, bool pickupFrozen, bool dropoffFrozen) async {
    final fillingPickup = fromController.text.trim().isEmpty;
    final target = fillingPickup ? fromController : toController;

    final result = await Navigator.push<Map<String, dynamic>>(
      state.context,
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

    if (result != null && state.mounted) {
      final lat = result['latitude'] as double?;
      final lon = result['longitude'] as double?;

      if (lat != null && lon != null) {
        if (fillingPickup) {
          setState(() {
            setPickupLat(lat);
            setPickupLon(lon);
            setPickupFrozen(true);
          });
        } else {
          setState(() {
            setDropoffLat(lat);
            setDropoffLon(lon);
            setDropoffFrozen(true);
          });
        }

        final place = await MapboxService.reverseGeocode(lat, lon);
        if (place != null && state.mounted) {
          setState(() => target.text = place.placeName);
        }

        if (fillingPickup) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (state.mounted) toFocus.requestFocus();
          });
        }
      }
    }
  }

  void maybeNavigate(double? pickupLat, double? pickupLon, double? dropoffLat, double? dropoffLon, String dropOff, String pickUp, DateTime pickedDate, TimeOfDay? pickedTime, int passengerCount) {
    if (pickUp.isEmpty || dropOff.isEmpty) return;

    if (pickedTime == null) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (pickupLat == null || pickupLon == null) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(
          content: Text('Pickup location is incomplete'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (dropoffLat == null || dropoffLon == null) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(
          content: Text('Drop-off location is incomplete'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    FocusScope.of(state.context).unfocus();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!state.mounted) return;
      Navigator.pushNamed(
        state.context,
        '/ride_booking_page',
        arguments: {
          'pickupLat': pickupLat,
          'pickupLon': pickupLon,
          'dropoffLat': dropoffLat,
          'dropoffLon': dropoffLon,
          'pickupAddress': pickUp,
          'dropoffAddress': dropOff,
          'date': pickedDate,
          'time': pickedTime,
          'passengerCount': passengerCount,
        },
      );
    });
  }
}
