import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'complete_profile_field_decoration.dart';

class CompleteProfileNameFields extends StatelessWidget {
  const CompleteProfileNameFields({
    super.key,
    required this.t,
    required this.firstNameController,
    required this.lastNameController,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.onChanged,
  });

  final AppLocalizations t;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── First Name ────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.translate('first_name'),
            style: AppTextStyles.sectionLabel(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: firstNameController,
          focusNode: firstNameFocus,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context),
          onTap: onChanged,
          onChanged: (_) => onChanged(),
          decoration: buildFieldDecoration(
            context,
            hint: t.translate('first_name'),
            prefixIcon: Icons.person_outline,
            focusNode: firstNameFocus,
          ),
        ),

        const SizedBox(height: 16),

        // ── Last Name ─────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.translate('last_name'),
            style: AppTextStyles.sectionLabel(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: lastNameController,
          focusNode: lastNameFocus,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context),
          onTap: onChanged,
          decoration: buildFieldDecoration(
            context,
            hint: t.translate('last_name'),
            prefixIcon: Icons.person_outline,
            focusNode: lastNameFocus,
          ),
        ),
      ],
    );
  }
}