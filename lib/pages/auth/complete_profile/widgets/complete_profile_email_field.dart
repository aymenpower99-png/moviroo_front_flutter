import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'complete_profile_field_decoration.dart';

class CompleteProfileEmailField extends StatelessWidget {
  const CompleteProfileEmailField({
    super.key,
    required this.t,
    required this.emailController,
    required this.emailFocus,
    required this.onTap,
  });

  final AppLocalizations t;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.translate('label_email_address'),
            style: AppTextStyles.sectionLabel(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          focusNode: emailFocus,
          readOnly: true,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context)
              .copyWith(color: AppColors.subtext(context)),
          onTap: onTap,
          decoration: buildFieldDecoration(
            context,
            hint: t.translate('hint_email'),
            prefixIcon: Icons.email_outlined,
            readOnly: true,
            focusNode: emailFocus,
          ),
        ),
      ],
    );
  }
}