import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Step 2 — 6-digit OTP input modal.
///
/// Returns the entered code string via [Navigator.pop],
/// or null if the user closes without verifying.
///
/// Usage:
/// ```dart
/// final code = await showDialog<String>(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => const EmailVerifyModal(),
/// );
/// ```
class EmailVerifyModal extends StatefulWidget {
  const EmailVerifyModal({super.key});

  @override
  State<EmailVerifyModal> createState() => _EmailVerifyModalState();
}

class _EmailVerifyModalState extends State<EmailVerifyModal> {
  static const int _codeLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  int _resendSeconds = 59;

  @override
  void initState() {
    super.initState();
    // Rebuild on focus changes so cell borders update immediately
    for (final f in _focusNodes) {
      f.addListener(() {
        if (mounted) setState(() {});
      });
    }
    // Auto-focus first cell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
    _startResendTimer();
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

  void _onDigitChanged(String value, int index) {
    // Handle paste — user pastes full code at once
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

  /// Handles backspace on an already-empty cell → move to previous cell and clear it
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Close button ────────────────────────────────────────────
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

            // ── Mail icon ───────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────────────
            Text(
              t('Enter Verification Code'),
              style: AppTextStyles.pageTitle(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ── Subtitle ────────────────────────────────────────────────
            Text(
              t('Enter the 6-digit code sent to your email'),
              style: AppTextStyles.bodySmall(context),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ── OTP cells ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
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
            ),

            const SizedBox(height: 20),

            // ── Verify button ───────────────────────────────────────────
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

            // ── Resend timer / link ─────────────────────────────────────
            _resendSeconds > 0
                ? Text(
                    '${t('Resend code in')} ${_resendSeconds}s',
                    style: AppTextStyles.bodySmall(context),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => _resendSeconds = 60);
                      _startResendTimer();
                      // TODO: trigger resend API call
                    },
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
        ),
      ),
    );
  }
}
