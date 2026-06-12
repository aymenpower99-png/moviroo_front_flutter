import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../../../../../theme/app_colors.dart';

class ConfirmUnlinkDialog extends StatefulWidget {
  const ConfirmUnlinkDialog({super.key});

  @override
  State<ConfirmUnlinkDialog> createState() => _ConfirmUnlinkDialogState();
}

class _ConfirmUnlinkDialogState extends State<ConfirmUnlinkDialog> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Remove Authentication App'),
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('enter_6digit_code_confirm_removal'),
              style: AppTextStyles.bodySmall(context),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Row(
                  children: [
                    if (index > 0) const SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      height: 50,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        autofocus: index == 0,
                        cursorColor: AppColors.primaryPurple,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.bg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryPurple,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOtpChanged(value, index),
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('Cancel'),
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final code = _otp.trim();
                      if (code.length == 6) Navigator.pop(context, code);
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('Remove'),
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}