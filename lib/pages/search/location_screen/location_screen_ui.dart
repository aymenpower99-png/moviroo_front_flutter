import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../LocationCard.dart';
import '../nextdestinationsearch.dart';
import '../RecentSearchItem.dart';
import '../datetime_row/datetime_row.dart';
import '../../../../services/geocoding/geocoding_service.dart';
import 'widgets.dart';

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
  final List<GeocodingPlace> recentPickupSearches;
  final List<GeocodingPlace> recentDropoffSearches;
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
  final Function() onClearPickupRecentSearches;
  final Function() onClearDropoffRecentSearches;

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
    required this.recentPickupSearches,
    required this.recentDropoffSearches,
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
    required this.onClearPickupRecentSearches,
    required this.onClearDropoffRecentSearches,
  });

  @override
  Widget build(BuildContext context) {
    final isPickupFocused = fromFocus.hasFocus;
    final currentRecentSearches = isPickupFocused
        ? recentPickupSearches
        : recentDropoffSearches;

    final showRecent =
        suggestions.isEmpty &&
        currentRecentSearches.isNotEmpty &&
        !(fromFocus.hasFocus && fromController.text.trim().isNotEmpty) &&
        !(toFocus.hasFocus && toController.text.trim().isNotEmpty);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Stack(
          children: [
            // Top header section (title + pills)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
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
                                    color: Colors.black.withValues(alpha: 0.08),
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
                          child: Pill(
                            icon: Icons.person_outline_rounded,
                            label: pillLabel,
                            onTap: onShowRiderSheet,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Pill(
                            icon: Icons.people_outline_rounded,
                            label:
                                '$passengerCount ${t.translate('passengers')}',
                            onTap: onShowPassengerPicker,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Scrollable body (positioned to fill available space below header)
            Positioned(
              top: 140, // Start below the header section (title + pills)
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationCard(
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
                    const SizedBox(height: 10),
                    DateTimeRow(
                      initialDate: pickedDate,
                      onDateChanged: onDateChanged,
                      onTimeChanged: onTimeChanged,
                    ),
                    const SizedBox(height: 14),
                    NextDestinationSearch(
                      suggestions: suggestions,
                      onSuggestionTap: onSuggestionTap,
                      onSelectOnMap: onSelectOnMap,
                    ),
                    if (showRecent) ...[
                      const SizedBox(height: 2),
                      ...(isPickupFocused
                              ? recentPickupSearches
                              : recentDropoffSearches)
                          .map(
                            (place) => RecentSearchTile(
                              item: RecentSearchItem(
                                title: place.placeName,
                                subtitle: place.fullAddress,
                                categoryIcon: place.categoryIcon,
                              ),
                              onTap: () =>
                                  onFillSmartField(place.placeName, place),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: isPickupFocused
                              ? onClearPickupRecentSearches
                              : onClearDropoffRecentSearches,
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

            // ── Confirm button (fixed at bottom, only shows when both fields are filled) ──
            if (fromController.text.trim().isNotEmpty &&
                toController.text.trim().isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
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
