import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/router.dart';

class CompleteProfileTopBar extends StatelessWidget {
  const CompleteProfileTopBar({super.key, required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => AppRouter.clearAndGo(context, AppRouter.login),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.text(context),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              t.translate('complete_profile'),
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionLabel(context)
                  .copyWith(color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}