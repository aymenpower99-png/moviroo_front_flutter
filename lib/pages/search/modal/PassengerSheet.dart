import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class PassengerSheet {
  static Future<int?> show(
    BuildContext context, {
    required int initialCount,
  }) async {
    int tempCount = initialCount;

    return await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // Resolve translations outside StatefulBuilder so they're stable
        final t = AppLocalizations.of(context);

        return StatefulBuilder(
          builder: (ctx, setBS) {
            return SizedBox(
              height: 320,
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Text(
                            t.translate('cancel'),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.subtext(context),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          t.translate('passengers'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx, tempCount),
                          child: Text(
                            t.translate('done'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Drum-roll picker
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            height: 48,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                            initialItem: tempCount - 1,
                          ),
                          itemExtent: 48,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setBS(() => tempCount = i + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 16,
                            builder: (_, i) => Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}