import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class LocationCard extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final Animation<double> pulseAnim;
  final VoidCallback onSwap;
  final VoidCallback? onUseCurrentLocation;
  final bool isFetchingLocation;
  final bool hasFocus;

  const LocationCard({
    super.key,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.pulseAnim,
    required this.onSwap,
    this.onUseCurrentLocation,
    this.isFetchingLocation = false,
    this.hasFocus = false,
  });

  InputDecoration _inputDec(
    BuildContext context, {
    required String hint,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      vertical: 14,
    ),
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.subtext(context),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: false,
    isDense: false,
    contentPadding: contentPadding,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: hasFocus
            ? Border.all(color: AppColors.primaryPurple, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Dot connector column ──────────────────────────────
            SizedBox(
              width: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, __) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: AppColors.primaryPurple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(
                              0.25 * pulseAnim.value,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...List.generate(
                    4,
                    (_) => Container(
                      width: 1.5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // ── Inputs ────────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Pick-up row ──
                  SizedBox(
                    height: 48,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fromController,
                            focusNode: fromFocus,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: _inputDec(
                              context,
                              hint: t.translate('pick_up'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: fromController,
                          builder: (_, val, __) => val.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => fromController.clear(),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppColors.subtext(context),
                                  ),
                                )
                              : isFetchingLocation
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryPurple,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: onUseCurrentLocation,
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    size: 22,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: AppColors.border(context),
                  ),
                  // ── Drop-off row ──
                  SizedBox(
                    height: 48,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: toController,
                            focusNode: toFocus,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: _inputDec(
                              context,
                              hint: t.translate('drop_off'),
                              contentPadding: const EdgeInsets.only(
                                top: 7,
                                bottom: 7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: toController,
                          builder: (_, val, __) => val.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: toController.clear,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppColors.subtext(context),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Swap button ──
            GestureDetector(
              onTap: onSwap,
              child: const Icon(
                Icons.swap_vert_rounded,
                size: 32,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
