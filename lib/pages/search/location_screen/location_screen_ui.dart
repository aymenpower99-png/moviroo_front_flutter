import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../LocationCard.dart';
import '../RecentSearchItem.dart';
import '../datetime_row/datetime_row.dart';
import '../../../../services/geocoding/geocoding_service.dart';

class LocationScreenUI extends StatelessWidget {
  final AppLocalizations t;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final Animation<double> pulseAnim;
  final String pillLabel;
  final int passengerCount;
  final DateTime pickedDate;
  final TimeOfDay? pickedTime;
  final List<GeocodingPlace> suggestions;
  final List<GeocodingPlace> nearbyPlaces;
  final List<GeocodingPlace> recentSearches;
  final List<GeocodingPlace> dropoffRecentSearches;
  final bool isLoadingSuggestions;
  final bool isLoadingNearbyPlaces;
  final bool isFetchingLocation;
  final bool isCardFocused;
  final bool canNavigate;
  final double? pickupLat;
  final double? pickupLon;

  final VoidCallback onSwap;
  final VoidCallback? onUseCurrentLocation;
  final Function(GeocodingPlace) onSuggestionTap;
  final VoidCallback onSelectOnMap;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?) onTimeChanged;
  final Function(String, GeocodingPlace) onFillSmartField;
  final VoidCallback onMaybeNavigate;
  final VoidCallback onShowRiderSheet;
  final VoidCallback onShowPassengerPicker;
  final Function() onClearRecentSearches;

  const LocationScreenUI({
    super.key,
    required this.t,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.pulseAnim,
    required this.pillLabel,
    required this.passengerCount,
    required this.pickedDate,
    required this.pickedTime,
    required this.suggestions,
    required this.nearbyPlaces,
    required this.recentSearches,
    required this.dropoffRecentSearches,
    required this.isLoadingSuggestions,
    required this.isLoadingNearbyPlaces,
    required this.isFetchingLocation,
    required this.isCardFocused,
    required this.canNavigate,
    this.pickupLat,
    this.pickupLon,
    required this.onSwap,
    required this.onUseCurrentLocation,
    required this.onSuggestionTap,
    required this.onSelectOnMap,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onFillSmartField,
    required this.onMaybeNavigate,
    required this.onShowRiderSheet,
    required this.onShowPassengerPicker,
    required this.onClearRecentSearches,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDropoffMode = toFocus.hasFocus;
    final activeRecentList = isDropoffMode ? dropoffRecentSearches : recentSearches;

    // "Select on map" is always available when any field is focused.
    final bool showSelectOnMap = fromFocus.hasFocus || toFocus.hasFocus;

    // Nearby places are shown when drop-off is focused and pickup has coordinates,
    // regardless of whether the user is typing.
    final bool showNearbyPlaces =
        toFocus.hasFocus && pickupLat != null && pickupLon != null;

    // Recent searches when the focused field is empty and no autocomplete is showing.
    final bool showRecent =
        suggestions.isEmpty &&
        activeRecentList.isNotEmpty &&
        (isDropoffMode
            ? toController.text.trim().isEmpty
            : fromController.text.trim().isEmpty);

    // True if the list is completely empty (no sections at all).
    final bool isCompletelyEmpty =
        suggestions.isEmpty &&
        !showSelectOnMap &&
        nearbyPlaces.isEmpty &&
        !showRecent;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    t.translate('plan_your_ride'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.text(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Passenger pill ──
            Center(
              child: _PassengerPill(
                label: '$passengerCount ${t.translate('passengers')}',
                onTap: onShowPassengerPicker,
              ),
            ),

            const SizedBox(height: 10),

            // ── Search box ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LocationCard(
                fromController: fromController,
                toController: toController,
                fromFocus: fromFocus,
                toFocus: toFocus,
                pulseAnim: pulseAnim,
                onSwap: onSwap,
                onUseCurrentLocation: isFetchingLocation
                    ? null
                    : onUseCurrentLocation,
                isFetchingLocation: isFetchingLocation,
                hasFocus: isCardFocused,
              ),
            ),

            const SizedBox(height: 10),

            // ── Date + Time row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DateTimeRow(
                initialDate: pickedDate,
                onDateChanged: onDateChanged,
                onTimeChanged: onTimeChanged,
              ),
            ),

            const SizedBox(height: 8),

            // ── Content list ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                children: [
                  // Section: Nearby places (shown FIRST so they stay visible)
                  // Only renders when drop-off is focused, pickup is confirmed,
                  // and we actually have results. No empty states, no messages.
                  if (showNearbyPlaces && nearbyPlaces.isNotEmpty) ...[
                    ...nearbyPlaces.map((place) => _SuggestionTile(
                          place: place,
                          onTap: () => onSuggestionTap(place),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Section: Autocomplete suggestions
                  if (suggestions.isNotEmpty) ...[
                    ...suggestions.map((place) => _SuggestionTile(
                          place: place,
                          onTap: () => onSuggestionTap(place),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Section: Select on map (always available when focused)
                  if (showSelectOnMap) ...[
                    _SelectOnMapTile(onTap: onSelectOnMap),
                    const SizedBox(height: 12),
                  ],

                  // Section: Recent searches
                  if (showRecent) ...[
                    ...activeRecentList.map((place) => RecentSearchTile(
                          item: RecentSearchItem(
                            title: place.localizedPlaceName(),
                            subtitle: place.localizedFullAddress(),
                            categoryIcon: Icons.history_rounded,
                          ),
                           onTap: () => onFillSmartField(place.localizedPlaceName(), place),
                        )),
                    if (activeRecentList.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ClearRecentTile(onTap: onClearRecentSearches),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Empty state when nothing is showing
                  if (isCompletelyEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 48,
                              color: AppColors.subtext(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.translate('start_typing_or_pick_map'),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.subtext(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Confirm button ──
            if (fromController.text.trim().isNotEmpty &&
                toController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: canNavigate ? onMaybeNavigate : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canNavigate
                          ? AppColors.primaryPurple
                          : Colors.grey,
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

// ── Icon box ───────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppColors.primaryPurple),
    );
  }
}

// ── Passenger Pill ─────────────────────────────────────────────────────────

class _PassengerPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PassengerPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 15,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion tile ────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final GeocodingPlace place;
  final VoidCallback onTap;

  const _SuggestionTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _IconBox(icon: place.categoryIcon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.localizedPlaceName(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),

                  // Address
                  if (place.localizedFullAddress().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        place.localizedFullAddress(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtext(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Select on map tile ─────────────────────────────────────────────────────

class _SelectOnMapTile extends StatelessWidget {
  final VoidCallback onTap;

  const _SelectOnMapTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const _IconBox(icon: Icons.map_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate('select_on_map'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.subtext(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clear recent searches tile (inline in header now) ──────────────────────
// Kept as a widget for backwards-compat if used elsewhere.
class _ClearRecentTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearRecentTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.subtext(context),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).translate('clear'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.subtext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
