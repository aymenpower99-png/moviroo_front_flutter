import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'otp_state.dart';
import 'otp_widgets.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with OtpStateMixin {
  @override
  void initState() {
    super.initState();
    initOtpArgs();
  }

  @override
  void dispose() {
    disposeOtp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Padding(
              // in otp_page.dart
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ), // was 16 or 28
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                      purpose == 'verify-email'
                          ? t.translate('otp_verify_email')
                          : purpose == 'login-totp'
                          ? t.translate('otp_authenticator_code')
                          : t.translate('otp_verify'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionLabel(context),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // ── Icon circle ───────────────────────────────
                    OtpIconCircle(purpose: purpose),

                    const SizedBox(height: 32),

                    // ── Title ─────────────────────────────────────
                    Text(
                      t.translate('otp_title'),
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 14),

                    // ── Subtitle ──────────────────────────────────
                    Text(
                      purpose == 'login-totp'
                          ? t.translate('otp_app_subtitle')
                          : t
                                .translate('otp_sent_to_email')
                                .replaceAll(
                                  '{email}',
                                  email ?? t.translate('your_email'),
                                ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(height: 1.6),
                    ),

                    const SizedBox(height: 64),

                    // ── OTP Input Fields ───────────────────────────
                    OtpInputRow(
                      controllers: otpControllers,
                      focusNodes: focusNodes,
                      onChanged: onOtpChanged,
                    ),

                    const SizedBox(height: 32),

                    // ── Error Message ──────────────────────────────
                    if (errorMessage != null)
                      OtpErrorMessage(message: errorMessage!),

                    const SizedBox(height: 32),

                    // ── Verify Button ──────────────────────────────
                    OtpVerifyButton(
                      isLoading: isLoading,
                      onPressed: handleVerifyOtp,
                    ),

                    const SizedBox(height: 24),

                    // ── Resend Link ────────────────────────────────
                    OtpResendButton(
                      isLoading: isLoading,
                      isResending: isResending,
                      purpose: purpose,
                      onPressed: handleResend,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
