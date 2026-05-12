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
  final List<GeocodingPlace> recentSearches;
  final bool isLoadingSuggestions;
  final bool isFetchingLocation;
  final bool isCardFocused;
  final bool canNavigate;

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
    required this.recentSearches,
    required this.isLoadingSuggestions,
    required this.isFetchingLocation,
    required this.isCardFocused,
    required this.canNavigate,
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
    final anyFieldFocused = fromFocus.hasFocus || toFocus.hasFocus;

    // Check if the currently focused field has text
    final focusedFieldHasText =
        (fromFocus.hasFocus && fromController.text.trim().isNotEmpty) ||
        (toFocus.hasFocus && toController.text.trim().isNotEmpty);

    // Show "Select on map" when:
    // - Any field is focused
    // - The focused field is empty (user hasn't typed yet)
    // - Suggestions are empty (or will be replaced by suggestions when typing)
    final showSelectOnMap = anyFieldFocused && !focusedFieldHasText;

    final showRecent =
        suggestions.isEmpty &&
        recentSearches.isNotEmpty &&
        fromController.text.trim().isEmpty &&
        toController.text.trim().isEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tight header (back + title) ──
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

            // ── Passenger pill (centered, top middle) ──
            Center(
              child: _PassengerPill(
                label: '$passengerCount ${t.translate('passengers')}',
                onTap: onShowPassengerPicker,
              ),
            ),

            const SizedBox(height: 10),

            // ── Compact search box ──
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

            // ── Date + Time row (after search input) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DateTimeRow(
                initialDate: pickedDate,
                onDateChanged: onDateChanged,
                onTimeChanged: onTimeChanged,
              ),
            ),

            const SizedBox(height: 8),

            // ── Suggestions list (takes all remaining space) ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                itemCount: _listItemCount(
                  showSelectOnMap,
                  showRecent,
                  isLoadingSuggestions,
                ),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border(context).withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  // Show suggestions only (no "Select on map")
                  if (suggestions.isNotEmpty) {
                    if (index < suggestions.length) {
                      final place = suggestions[index];
                      return _SuggestionTile(
                        place: place,
                        onTap: () => onSuggestionTap(place),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  // Show "Select on map" + recent searches
                  if (showSelectOnMap) {
                    if (index == 0) {
                      return _SelectOnMapTile(onTap: onSelectOnMap);
                    }
                    if (showRecent) {
                      final recentIndex = index - 1;
                      if (recentIndex < recentSearches.length) {
                        final place = recentSearches[recentIndex];
                        return RecentSearchTile(
                          item: RecentSearchItem(
                            title: place.placeName,
                            subtitle: place.fullAddress,
                            categoryIcon: Icons.location_on_outlined,
                          ),
                          onTap: () => onFillSmartField(place.placeName, place),
                        );
                      }
                      if (recentIndex == recentSearches.length) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: _ClearRecentTile(onTap: onClearRecentSearches),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  }

                  // Loading state
                  if (isLoadingSuggestions) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
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

  int _listItemCount(bool showSelectOnMap, bool showRecent, bool isLoading) {
    if (suggestions.isNotEmpty) return suggestions.length;
    int count = 0;
    if (showSelectOnMap) count += 1; // select-on-map only
    if (showRecent) count += recentSearches.length + 1; // + "Clear"
    if (isLoading && count == 0) count += 1;
    return count;
  }
}

// ── Passenger Pill (centered, top middle) ──
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

// ── Icon box matching RecentSearchTile styling ──
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

// ── Suggestion tile ──
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
            _IconBox(icon: place.categoryIcon ?? Icons.location_on_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.placeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.fullAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        place.fullAddress,
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

// ── Select on map tile ──
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

// ── Clear recent searches tile ──
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
