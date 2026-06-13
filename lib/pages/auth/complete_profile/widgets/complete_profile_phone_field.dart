import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'complete_profile_field_decoration.dart';

class CompleteProfilePhoneField extends StatelessWidget {
  const CompleteProfilePhoneField({
    super.key,
    required this.t,
    required this.phoneController,
    required this.phoneFocus,
    required this.onTap,
  });

  final AppLocalizations t;
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final VoidCallback onTap;

  Widget _flagPrefix(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'images/flags/tunisia.png',
              width: 24,
              height: 16,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+216',
            style: AppTextStyles.bodyMedium(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.translate('phone_number'),
            style: AppTextStyles.sectionLabel(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          focusNode: phoneFocus,
          keyboardType: TextInputType.phone,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.bodyMedium(context),
          onTap: onTap,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: buildFieldDecoration(
            context,
            hint: t.translate('hint_phone_tunisia'),
            prefixIcon: Icons.phone_outlined,
            focusNode: phoneFocus,
            prefix: _flagPrefix(context),
          ),
        ),
      ],
    );
  }
}