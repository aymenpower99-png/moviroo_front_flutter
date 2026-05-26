import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../../../../../../theme/app_text_styles.dart';
import '../../../../../../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../../../../../../theme/app_colors.dart';
import 'qr_view.dart';
import '../shared/primary_button.dart';
import '../shared/step_label.dart';

class SetupView extends StatefulWidget {
  final String secret;
  final String? qrDataUrl;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onLink;

  const SetupView({
    super.key,
    required this.secret,
    required this.qrDataUrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onLink,
  });

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  bool _copied = false;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  void _copySecret() {
    Clipboard.setData(ClipboardData(text: widget.secret));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        StepLabel(number: '1', label: t('Scan the QR Code')),
        const SizedBox(height: 12),

        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QrView(dataUrl: widget.qrDataUrl),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          t('Or enter the setup key manually:'),
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _copySecret,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.secret,
                    style: AppTextStyles.settingsItem(
                      context,
                    ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _copied
                      ? Icons.check_circle_outline_rounded
                      : Icons.copy_rounded,
                  size: 18,
                  color: _copied
                      ? AppColors.success
                      : AppColors.subtext(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Divider(color: AppColors.border(context)),
        const SizedBox(height: 24),

        StepLabel(number: '2', label: t('Enter the 6-digit code')),
        const SizedBox(height: 12),
        Text(
          t('Open your authenticator app and enter the code shown.'),
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: 16),

        // ── OTP boxes — Expanded so they never overflow ──────────────────
        Row(
          children: List.generate(6, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == 5 ? 0 : 4,
                ),
                child: SizedBox(
                  height: 54,
                  width: 54,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    maxLength: 1,
                    cursorColor: AppColors.primaryPurple,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppColors.surface(context),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onOtpChanged(value, index),
                  ),
                ),
              ),
            );
          }),
        ),

        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        PrimaryButton(
          label: t('Verify & Link'),
          isLoading: widget.isLoading,
          onTap: () => widget.onLink(_otp),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
