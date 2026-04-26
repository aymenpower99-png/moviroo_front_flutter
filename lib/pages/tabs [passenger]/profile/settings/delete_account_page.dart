import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../routing/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../services/passkey/passkey_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

/// ReAuth method the user picks to prove identity before hard delete.
enum _ReAuthMethod { password, emailOtp, passkey }

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _auth = AuthService();
  final _passkey = PasskeyService();

  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  _ReAuthMethod _method = _ReAuthMethod.password;

  bool _obscure = true;
  bool _isBootstrapping = true;
  bool _isBusy = false;
  bool _otpSent = false;

  bool _has2fa = false;
  bool _hasPasskey = false;
  bool _passkeyDeviceSupported = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final user = await _auth.getCurrentUser(forceRefresh: true);
      final supported = await _passkey.isSupported();
      if (!mounted) return;
      setState(() {
        _has2fa = (user?['is2faEnabled'] as bool?) ?? false;
        _hasPasskey = (user?['passkeyEnabled'] as bool?) ?? false;
        _passkeyDeviceSupported = supported;
        _isBootstrapping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBootstrapping = false);
    }
  }

  Future<void> _requestOtp() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await _auth.requestDeleteOtp();
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent to your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete your account?',
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action is permanent. All your data, rides, and payment '
          'methods will be removed. You cannot undo this.',
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.subtext(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete permanently',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _performDelete();
  }

  Future<void> _performDelete() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_method) {
        case _ReAuthMethod.password:
          await _auth.deleteAccount(password: _passwordCtrl.text);
          break;

        case _ReAuthMethod.emailOtp:
          if (_otpCtrl.text.length != 6) {
            throw Exception('Enter the 6-digit code sent to your email.');
          }
          await _auth.deleteAccount(otp: _otpCtrl.text);
          break;

        case _ReAuthMethod.passkey:
          final challenge = await _passkey.challenge(
            reason: 'Confirm your identity to delete your account.',
          );
          if (!challenge.success || challenge.actionToken == null) {
            throw Exception(challenge.errorMessage ?? 'Passkey cancelled.');
          }
          await _auth.deleteAccount(passkeyToken: challenge.actionToken);
          break;
      }

      if (!mounted) return;
      // AuthService already cleared tokens.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account deleted.')));
      AppRouter.clearAndGo(context, AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _canSubmit {
    if (_isBusy) return false;
    switch (_method) {
      case _ReAuthMethod.password:
        return _passwordCtrl.text.isNotEmpty;
      case _ReAuthMethod.emailOtp:
        return _otpSent && _otpCtrl.text.length == 6;
      case _ReAuthMethod.passkey:
        return _passkeyDeviceSupported;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: t('delete_account')),
            if (_isBootstrapping)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPurple,
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _WarningBanner(),
                      const SizedBox(height: 24),
                      Text(
                        'VERIFY YOUR IDENTITY',
                        style: AppTextStyles.sectionLabel(context),
                      ),
                      const SizedBox(height: 12),
                      _MethodTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Password',
                        subtitle: 'Enter your current password',
                        selected: _method == _ReAuthMethod.password,
                        onTap: () => setState(() {
                          _method = _ReAuthMethod.password;
                          _errorMessage = null;
                        }),
                      ),
                      if (_has2fa) ...[
                        const SizedBox(height: 10),
                        _MethodTile(
                          icon: Icons.mail_outline_rounded,
                          title: 'Email verification code',
                          subtitle: 'We will send a 6-digit code to your email',
                          selected: _method == _ReAuthMethod.emailOtp,
                          onTap: () => setState(() {
                            _method = _ReAuthMethod.emailOtp;
                            _errorMessage = null;
                          }),
                        ),
                      ],
                      if (_hasPasskey && _passkeyDeviceSupported) ...[
                        const SizedBox(height: 10),
                        _MethodTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Passkey',
                          subtitle: 'Use Face ID, Fingerprint, or device PIN',
                          selected: _method == _ReAuthMethod.passkey,
                          onTap: () => setState(() {
                            _method = _ReAuthMethod.passkey;
                            _errorMessage = null;
                          }),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _MethodInput(
                        method: _method,
                        passwordCtrl: _passwordCtrl,
                        otpCtrl: _otpCtrl,
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        otpSent: _otpSent,
                        isBusy: _isBusy,
                        onSendOtp: _requestOtp,
                        onChanged: () => setState(() {}),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
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
                                  _errorMessage!,
                                  style: AppTextStyles.bodySmall(
                                    context,
                                  ).copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _DeleteButton(
                        enabled: _canSubmit,
                        isLoading: _isBusy,
                        onTap: _confirmDelete,
                      ),
                      const SizedBox(height: 24),
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

// ── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.text(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── Warning Banner ──────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete your account',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All data including ride history, saved places, and payment '
                  'methods will be removed. This cannot be undone.',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Method selection tile ──────────────────────────────────────────────────

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryPurple
                : AppColors.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge(context)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primaryPurple
                      : AppColors.border(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Method-specific input ──────────────────────────────────────────────────

class _MethodInput extends StatelessWidget {
  final _ReAuthMethod method;
  final TextEditingController passwordCtrl;
  final TextEditingController otpCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool otpSent;
  final bool isBusy;
  final VoidCallback onSendOtp;
  final VoidCallback onChanged;

  const _MethodInput({
    required this.method,
    required this.passwordCtrl,
    required this.otpCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.otpSent,
    required this.isBusy,
    required this.onSendOtp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (method) {
      case _ReAuthMethod.password:
        return TextField(
          controller: passwordCtrl,
          obscureText: obscure,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Current password',
            filled: true,
            fillColor: AppColors.surface(context),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primaryPurple,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.subtext(context),
              ),
              onPressed: onToggleObscure,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        );

      case _ReAuthMethod.emailOtp:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!otpSent)
              GestureDetector(
                onTap: isBusy ? null : onSendOtp,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send verification code',
                          style: AppTextStyles.buttonPrimary,
                        ),
                ),
              )
            else
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(letterSpacing: 8, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
            if (otpSent) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: isBusy ? null : onSendOtp,
                child: Text(
                  'Resend code',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.primaryPurple),
                ),
              ),
            ],
          ],
        );

      case _ReAuthMethod.passkey:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.iconBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You'll be prompted for your device biometric when you tap delete.",
                  style: AppTextStyles.bodySmall(context),
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ── Delete button ───────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _DeleteButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !isLoading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? AppColors.error : AppColors.error.withValues(alpha: 0.4),
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
            : Text('Delete account', style: AppTextStyles.buttonPrimary),
      ),
    );
  }
}
