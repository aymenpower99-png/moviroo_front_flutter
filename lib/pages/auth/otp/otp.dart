import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../routing/router.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _userId;
  String? _purpose;
  String? _email;
  String? _preAuthToken;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Get arguments from navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _userId = args['userId'] as String?;
          _purpose = args['purpose'] as String?;
          _email = args['email'] as String?;
          _preAuthToken = args['preAuthToken'] as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_purpose == 'verify-email') {
        if (_userId == null) {
          setState(() => _errorMessage = 'Missing user ID');
          return;
        }
        await _authService.verifyEmail(userId: _userId!, code: otp);
        if (mounted) {
          AppRouter.clearAndGo(context, AppRouter.home);
        }
      } else if (_purpose == 'login-otp' || _purpose == 'login-totp') {
        if (_preAuthToken == null || _preAuthToken!.isEmpty) {
          setState(() => _errorMessage = 'Missing authentication token');
          return;
        }
        await _authService.verifyLoginOtp(
          preAuthToken: _preAuthToken!,
          code: otp,
        );
        await _authService.getCurrentUser(forceRefresh: true);
        if (mounted) {
          AppRouter.clearAndGo(context, AppRouter.home);
        }
      } else {
        setState(() => _errorMessage = 'Unknown verification purpose');
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      if (_purpose == 'verify-email' && _userId != null) {
        await _authService.resendVerification(_email ?? '');
      } else if (_purpose == 'login-otp' && _userId != null) {
        await _authService.resendLoginOtp(_userId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      _purpose == 'verify-email'
                          ? 'Verify Email'
                          : _purpose == 'login-totp'
                          ? 'Authenticator Code'
                          : 'Verify OTP',
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
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // ── Icon circle ───────────────────────────────
                    Container(
                      width: 88,
                      height: 88,
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
                      child: Icon(
                        _purpose == 'login-totp'
                            ? Icons.phonelink_lock_rounded
                            : Icons.verified_user_rounded,
                        color: AppColors.primaryPurple,
                        size: 38,
                      ),
                    ),

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
                      _purpose == 'verify-email'
                          ? 'Enter the 6-digit code sent to ${_email ?? 'your email'}'
                          : _purpose == 'login-totp'
                          ? 'Open your authenticator app and enter the current 6-digit code'
                          : 'Enter the 6-digit code sent to ${_email ?? 'your email'}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(height: 1.6),
                    ),

                    const SizedBox(height: 64),

                    // ── OTP Input Fields ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 50,
                          height: 60,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            cursorColor: AppColors.primaryPurple,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
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
                                borderSide: BorderSide(
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
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ── Error Message ───────────────────────────────
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Verify Button ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
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
                                t.translate('verify'),
                                style: AppTextStyles.buttonPrimary,
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Resend Link ─────────────────────────────
                    TextButton(
                      onPressed:
                          (_isLoading ||
                                  _isResending ||
                                  _purpose == 'login-totp')
                              ? null
                              : _handleResend,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryPurple,
                              ),
                            )
                          : Text(
                              t.translate('resend_code'),
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPurple,
                              ),
                            ),
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
