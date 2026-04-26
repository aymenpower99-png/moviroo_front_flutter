import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '_SummaryCard.dart';

class DiscountSection extends StatelessWidget {
  const DiscountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primaryPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('discount_code'),
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: AppTextStyles.bodyMedium(context),
                  decoration: InputDecoration(
                    hintText: t.translate('enter_code'),
                    hintStyle: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.subtext(context)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  t.translate('apply'),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
