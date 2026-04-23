import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/auth_service.dart';
import 'auth_app_page.dart';
import '2_step_ver_modal/email_send_modal.dart';

class TwoStepVerificationPage extends StatefulWidget {
  const TwoStepVerificationPage({super.key});

  @override
  State<TwoStepVerificationPage> createState() =>
      _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  final _authService = AuthService();

  bool _emailEnabled = false;
  bool _authAppEnabled = false;
  TwoFactorMethod? _primary;

  bool _isBootstrapping = true;
  bool _busyEmail = false;
  bool _busyTotp = false;
  bool _busyPrimary = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Show cached data immediately to avoid the 1-2s spinner
    final cached = _authService.getCachedUser();
    if (cached != null && mounted) {
      setState(() {
        _emailEnabled = (cached['is2faEnabled'] as bool?) ?? false;
        _authAppEnabled = (cached['totpEnabled'] as bool?) ?? false;
        _primary = twoFactorMethodFromString(
          cached['primary2faMethod'] as String?,
        );
        _isBootstrapping = false;
      });
    }
    // Then refresh from backend in background
    try {
      final user = await _authService.getCurrentUser(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _emailEnabled = (user?['is2faEnabled'] as bool?) ?? false;
        _authAppEnabled = (user?['totpEnabled'] as bool?) ?? false;
        _primary = twoFactorMethodFromString(
          user?['primary2faMethod'] as String?,
        );
        _isBootstrapping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_isBootstrapping) {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
        _isBootstrapping = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleEmail(bool val) async {
    if (_busyEmail) return;

    if (val) {
      // Show the two-step email OTP modal; pops with the verified code or null.
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const EmailSendModal(),
      );
      if (code == null || !mounted) return; // user cancelled

      setState(() {
        _busyEmail = true;
        _errorMessage = null;
      });
      try {
        final result = await _authService.toggleEmail2fa(true, otp: code);
        if (!mounted) return;
        setState(() {
          _emailEnabled = (result['is2faEnabled'] as bool?) ?? true;
          // One-method-at-a-time: enabling email also disables TOTP on the backend.
          _authAppEnabled = (result['totpEnabled'] as bool?) ?? false;
          _primary = twoFactorMethodFromString(
            result['primary2faMethod'] as String?,
          );
        });
      } catch (e) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _busyEmail = false);
      }
    } else {
      setState(() {
        _busyEmail = true;
        _errorMessage = null;
      });
      try {
        final result = await _authService.toggleEmail2fa(false);
        if (!mounted) return;
        setState(() {
          _emailEnabled = (result['is2faEnabled'] as bool?) ?? false;
          _primary = twoFactorMethodFromString(
            result['primary2faMethod'] as String?,
          );
        });
      } catch (e) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _busyEmail = false);
      }
    }
  }

  Future<void> _toggleAuthApp(bool val) async {
    if (_busyTotp) return;
    if (val) {
      // Go through full setup flow via AuthAppPage; that page confirms via TOTP
      // code with the backend and pops `true` on success.
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthAppPage()),
      );
      if (!mounted) return;
      if (result == true) {
        // One-method-at-a-time: TOTP is now active, email is off, TOTP is primary.
        // Apply immediately — no spinner — then reconcile silently with backend.
        setState(() {
          _authAppEnabled = true;
          _emailEnabled = false;
          _primary = TwoFactorMethod.totp;
          _errorMessage = null;
        });
        _authService.getCurrentUser(forceRefresh: true).then((user) {
          if (!mounted || user == null) return;
          setState(() {
            _authAppEnabled = (user['totpEnabled'] as bool?) ?? true;
            _emailEnabled = (user['is2faEnabled'] as bool?) ?? false;
            _primary =
                twoFactorMethodFromString(
                  user['primary2faMethod'] as String?,
                ) ??
                TwoFactorMethod.totp;
          });
        }).catchError((_) {});
      }
    } else {
      setState(() {
        _busyTotp = true;
        _errorMessage = null;
      });
      try {
        final result = await _authService.disableTotp();
        if (!mounted) return;
        setState(() {
          _authAppEnabled = (result['totpEnabled'] as bool?) ?? false;
          _primary = twoFactorMethodFromString(
            result['primary2faMethod'] as String?,
          );
        });
      } catch (e) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _busyTotp = false);
      }
    }
  }

  Future<void> _makePrimary(TwoFactorMethod target) async {
    if (_busyPrimary || _primary == target) return;
    if (target == TwoFactorMethod.email && !_emailEnabled) return;
    if (target == TwoFactorMethod.totp && !_authAppEnabled) return;

    // Identity must be proven with the CURRENT primary. If none yet, the target.
    final verifyAgainst = _primary ?? target;

    // If verifying via email, ask backend to send a fresh OTP first.
    if (verifyAgainst == TwoFactorMethod.email) {
      try {
        await _authService.requestPrimarySwitchEmailOtp();
      } catch (e) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        return;
      }
    }

    if (!mounted) return;
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerifyCodeDialog(
        title: verifyAgainst == TwoFactorMethod.email
            ? 'Enter email code'
            : 'Enter authenticator code',
        subtitle: verifyAgainst == TwoFactorMethod.email
            ? 'We sent a 6-digit code to your email.'
            : 'Open your authenticator app and enter the current 6-digit code.',
      ),
    );
    if (code == null || code.length != 6 || !mounted) return;

    setState(() {
      _busyPrimary = true;
      _errorMessage = null;
    });
    try {
      final result = await _authService.switchPrimary2fa(
        method: target,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _primary =
            twoFactorMethodFromString(result['primary2faMethod'] as String?) ??
            target;
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyPrimary = false);
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
            _SubPageTopBar(title: t('2-Step Verification')),
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
                      _InfoBanner(
                        text: t(
                          '2-step verification adds an extra layer of security to your account by requiring a second form of verification when you sign in.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t('VERIFICATION METHODS').toUpperCase(),
                        style: AppTextStyles.sectionLabel(context),
                      ),
                      const SizedBox(height: 12),
                      _VerificationMethodTile(
                        icon: Icons.mail_outline_rounded,
                        title: t('Email'),
                        subtitle: t(
                          'Receive a code to your registered email address',
                        ),
                        enabled: _emailEnabled,
                        busy: _busyEmail,
                        isPrimary: _primary == TwoFactorMethod.email,
                        canMakePrimary:
                            _emailEnabled && _primary != TwoFactorMethod.email,
                        onToggle: _toggleEmail,
                        onMakePrimary: () =>
                            _makePrimary(TwoFactorMethod.email),
                      ),
                      const SizedBox(height: 12),
                      _VerificationMethodTile(
                        icon: Icons.phonelink_lock_rounded,
                        title: t('Authenticator App'),
                        subtitle: t('Use an authenticator app for 2FA'),
                        enabled: _authAppEnabled,
                        busy: _busyTotp,
                        isPrimary: _primary == TwoFactorMethod.totp,
                        canMakePrimary:
                            _authAppEnabled && _primary != TwoFactorMethod.totp,
                        onToggle: _toggleAuthApp,
                        onMakePrimary: () => _makePrimary(TwoFactorMethod.totp),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
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
                      if (_busyPrimary) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
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

// ── Info Banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verification Method Tile ──────────────────────────────────────────────────

class _VerificationMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool busy;
  final bool isPrimary;
  final bool canMakePrimary;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMakePrimary;

  const _VerificationMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.busy,
    required this.isPrimary,
    required this.canMakePrimary,
    required this.onToggle,
    required this.onMakePrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? AppColors.primaryPurple : AppColors.border(context),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyLarge(context),
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPurple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTextStyles.bodySmall(context)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : _PurpleSwitch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (canMakePrimary) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onMakePrimary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Make primary',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Verification code dialog (used when switching primary method) ──────────

class _VerifyCodeDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  const _VerifyCodeDialog({required this.title, required this.subtitle});

  @override
  State<_VerifyCodeDialog> createState() => _VerifyCodeDialogState();
}

class _VerifyCodeDialogState extends State<_VerifyCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.pageTitle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: AppTextStyles.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(letterSpacing: 8, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                filled: true,
                fillColor: AppColors.iconBg(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.iconBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyLarge(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _controller.text.length == 6
                        ? () => Navigator.of(context).pop(_controller.text)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: _controller.text.length == 6
                            ? AppColors.purpleGradient
                            : null,
                        color: _controller.text.length == 6
                            ? null
                            : AppColors.border(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Verify',
                        style: AppTextStyles.buttonPrimary.copyWith(
                          color: _controller.text.length == 6
                              ? Colors.white
                              : AppColors.subtext(context),
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

// ── Purple Switch ─────────────────────────────────────────────────────────────

class _PurpleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PurpleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          gradient: value ? AppColors.purpleGradient : null,
          color: value ? null : AppColors.border(context),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _SubPageTopBar extends StatelessWidget {
  final String title;
  const _SubPageTopBar({required this.title});

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
