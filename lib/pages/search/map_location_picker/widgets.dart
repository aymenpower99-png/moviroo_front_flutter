import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CenterPin extends StatelessWidget {
  const CenterPin();

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
  const BackBtn({required this.onTap});

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
  const LocationBtn({required this.isLoading, required this.onTap});

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

  const PickerBottomSheet({
    required this.confirmLabel,
    required this.addressController,
    required this.isLoading,
    required this.isOutOfCoverage,
    required this.onConfirm,
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
            // Bold title (centered)
            const Text(
              'Your Pickup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtitle (centered)
            Text(
              'Tap button to confirm',
              style: AppTextStyles.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

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
