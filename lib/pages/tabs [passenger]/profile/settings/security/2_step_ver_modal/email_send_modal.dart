import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../services/auth_service/auth_service.dart';

enum _Step { send, verify }

/// Two-step email verification dialog for enabling email 2FA.
///
/// Step 1: Sends OTP via POST /auth/2fa/email/request-otp.
/// Step 2: User enters the 6-digit code.
///
/// Pops with the verified code String on success, or null if cancelled.
class EmailSendModal extends StatefulWidget {
  const EmailSendModal({super.key});

  @override
  State<EmailSendModal> createState() => _EmailSendModalState();
}

class _EmailSendModalState extends State<EmailSendModal> {
  final _authService = AuthService();

  _Step _step = _Step.send;
  bool _isSending = false;
  String? _errorMessage;

  // Step 2 OTP fields
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    for (final f in _focusNodes) {
      f.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await _authService.requestEmail2faEnableOtp();
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _step = _Step.verify;
        _resendSeconds = 59;
      });
      _startResendTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[0].requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _resendCode() async {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _errorMessage = null;
      _resendSeconds = 59;
    });
    _startResendTimer();
    _focusNodes[0].requestFocus();
    try {
      await _authService.requestEmail2faEnableOtp();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final next = digits.length < _codeLength
          ? digits.length
          : _codeLength - 1;
      _focusNodes[next].requestFocus();
      setState(() {});
      return;
    }
    if (value.length == 1 && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _enteredCode.length == _codeLength;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Close button ───────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.iconBg(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.text(context),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Mail icon ──────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),

            const SizedBox(height: 20),

            if (_step == _Step.send) ...[
              // ── Step 1: send code ────────────────────────────────────
              Text(
                t('Verify Your Email'),
                style: AppTextStyles.pageTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  "We'll send a 6-digit verification code to your registered email address.",
                ),
                style: AppTextStyles.bodySmall(context),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 28),
              _GradientButton(
                label: t('Send Verification Code'),
                isLoading: _isSending,
                onTap: _sendCode,
              ),
            ] else ...[
              // ── Step 2: enter code ───────────────────────────────────
              Text(
                t('Enter Verification Code'),
                style: AppTextStyles.pageTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t('Enter the 6-digit code sent to your email'),
                style: AppTextStyles.bodySmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // OTP cells
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) {
                  final isFocused = _focusNodes[i].hasFocus;
                  final isFilled = _controllers[i].text.isNotEmpty;
                  return SizedBox(
                    width: 40,
                    height: 50,
                    child: KeyboardListener(
                      focusNode: FocusNode(skipTraversal: true),
                      onKeyEvent: (e) => _onKeyEvent(e, i),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isFocused
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.10)
                              : const Color(0xFF7C3AED).withValues(alpha: 0.06),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isFilled
                                  ? const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.6)
                                  : const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => _onDigitChanged(v, i),
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _isComplete
                    ? () => Navigator.of(context).pop(_enteredCode)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isComplete ? AppColors.purpleGradient : null,
                    color: _isComplete
                        ? null
                        : const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t('Verify Code'),
                    style: AppTextStyles.buttonPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _resendSeconds > 0
                  ? Text(
                      '${t('Resend code in')} ${_resendSeconds}s',
                      style: AppTextStyles.bodySmall(context),
                    )
                  : GestureDetector(
                      onTap: _resendCode,
                      child: Text(
                        t('Resend code'),
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: const Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.purpleGradient,
          color: isLoading
              ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AppTextStyles.buttonPrimary),
      ),
    );
  }
}
