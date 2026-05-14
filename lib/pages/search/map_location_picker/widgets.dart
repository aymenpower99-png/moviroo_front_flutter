import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../../services/geocoding/geocoding_service.dart';

class CenterPin extends StatelessWidget {
  const CenterPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Head — filled circle (primary) with a white inner dot.
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryPurple,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
        // Stem — thin rounded rectangle beneath the head.
        Container(
          width: 4,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}

class BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const BackBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

class SearchInput extends StatelessWidget {
  final TextEditingController addressController;
  final bool isLoading;
  final bool isOutOfCoverage;

  const SearchInput({
    super.key,
    required this.addressController,
    required this.isLoading,
    required this.isOutOfCoverage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Colored dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOutOfCoverage
                  ? AppColors.error
                  : AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          // Address text
          Expanded(
            child: isLoading
                ? Text(
                    'Locating…',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.subtext(context)),
                  )
                : isOutOfCoverage
                ? Text(
                    'Not available in this region yet',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.error),
                  )
                : Text(
                    addressController.text.trim().isEmpty
                        ? 'Pin location'
                        : addressController.text,
                    style: AppTextStyles.bodyMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class LocationBtn extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const LocationBtn({super.key, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPurple,
                  ),
                ),
              )
            : Icon(
                Icons.my_location_rounded,
                size: 22,
                color: AppColors.text(context),
              ),
      ),
    );
  }
}

class PickerBottomSheet extends StatelessWidget {
  final String confirmLabel;
  final TextEditingController addressController;
  final bool isLoading;
  final bool isOutOfCoverage;
  final VoidCallback? onConfirm;
  final List<GeocodingPlace> nearbyPlaces;
  final bool isLoadingNearby;
  final ValueChanged<GeocodingPlace>? onNearbyPlaceSelected;

  const PickerBottomSheet({
    super.key,
    required this.confirmLabel,
    required this.addressController,
    required this.isLoading,
    required this.isOutOfCoverage,
    required this.onConfirm,
    this.nearbyPlaces = const [],
    this.isLoadingNearby = false,
    this.onNearbyPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Address display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text(
                      addressController.text.trim().isNotEmpty
                          ? addressController.text
                          : 'Drag map to select location',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Nearby places
            if (isLoadingNearby)
              const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (nearbyPlaces.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nearby',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtext(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearbyPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final place = nearbyPlaces[index];
                    return ActionChip(
                      avatar: Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: AppColors.primaryPurple,
                      ),
                      label: Text(
                        place.placeName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.bg(context),
                      side: BorderSide(color: AppColors.border(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () => onNearbyPlaceSelected?.call(place),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Confirm button
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfCoverage
                    ? AppColors.border(context)
                    : null,
                disabledBackgroundColor: AppColors.border(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                confirmLabel,
                style: AppTextStyles.buttonPrimary.copyWith(
                  color: isOutOfCoverage ? AppColors.subtext(context) : null,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
