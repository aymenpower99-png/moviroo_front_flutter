import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../../services/auth_service.dart';

class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({super.key});

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  bool _isResending = false;
  bool _isChecking = false;
  final AuthService _authService = AuthService();

  Future<void> _handleResend() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] ?? '';

    if (email.isEmpty) return;

    setState(() => _isResending = true);

    try {
      await _authService.resendVerification(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification link resent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _handleVerified() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] ?? '';
    final password = args?['password'] ?? '';

    // If we don't have password, just go to login
    if (password.isEmpty) {
      AppRouter.clearAndGo(context, AppRouter.login);
      return;
    }

    setState(() => _isChecking = true);

    try {
      final result = await _authService.login(email: email, password: password);
      if (mounted) {
        if (result['requiresVerification'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email not verified yet. Please check your email.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          AppRouter.clearAndGo(context, AppRouter.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] ?? '';
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Mail icon ───────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.iconBg(context),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A2A55)
                        : const Color(0xFFE9D5FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primaryPurple,
                  size: 44,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                t.translate('check_your_email'),
                style: AppTextStyles.pageTitle(
                  context,
                ).copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                t.translate('verification_link_sent'),
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
              ),

              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  t.translate('click_link_to_verify'),
                  style: AppTextStyles.bodySmall(context),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // ── Resend verification link ─────────────────────────
              TextButton(
                onPressed: _isResending ? null : _handleResend,
                child: _isResending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                      )
                    : Text(
                        t.translate('resend_verification_link'),
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              // ── I have verified my account ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'I have verified my account',
                          style: AppTextStyles.buttonPrimary,
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
