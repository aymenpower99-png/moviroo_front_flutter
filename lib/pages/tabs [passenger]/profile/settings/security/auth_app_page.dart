import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../services/auth_service/auth_service.dart';
import '2_step_ver_modal/auth_app_confirm_modal.dart'; // ← import the extracted modal

class AuthAppPage extends StatefulWidget {
  const AuthAppPage({super.key});

  @override
  State<AuthAppPage> createState() => _AuthAppPageState();
}

class _AuthAppPageState extends State<AuthAppPage> {
  final _authService = AuthService();

  bool _isLinked = false;
  bool _isBootstrapping = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Populated by POST /auth/2fa/totp/setup
  String? _setupSecret;
  String? _qrDataUrl; // data:image/png;base64,...

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Read cached user to know if TOTP already linked
      final cached = _authService.getCachedUser();
      final alreadyLinked = (cached?['totpEnabled'] as bool?) ?? false;

      if (alreadyLinked) {
        if (!mounted) return;
        setState(() {
          _isLinked = true;
          _isBootstrapping = false;
        });
        return;
      }

      // Not linked yet → fetch fresh QR + secret
      final data = await _authService.setupTotp();
      if (!mounted) return;
      setState(() {
        _setupSecret = data['secret'] as String?;
        _qrDataUrl = data['qrCodeUrl'] as String?;
        _isBootstrapping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isBootstrapping = false;
      });
    }
  }

  Future<void> _handleLink(String code) async {
    // Guard against double-tap: the state rebuild hasn't happened yet when a
    // second finger event fires, so we check _isLoading directly here.
    if (_isLoading) return;
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.confirmTotp(code);
      if (!mounted) return;
      // Pop immediately — don't flash the LinkedView before leaving.
      // The caller's _bootstrap() will fetch fresh state and flip the toggle.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      // Fallback: ensure loading is reset if still true (e.g. unmounted mid-call)
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnlink() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => const AuthAppConfirmModal(),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.disableTotp();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLinked = false;
      });
      // Fetch a fresh secret for re-link
      final data = await _authService.setupTotp();
      if (!mounted) return;
      setState(() {
        _setupSecret = data['secret'] as String?;
        _qrDataUrl = data['qrCodeUrl'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
            _SubPageTopBar(title: t('Authentication App')),
            Expanded(
              child: _isBootstrapping
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLinked
                          ? _LinkedView(
                              isLoading: _isLoading,
                              onUnlink: _handleUnlink,
                            )
                          : _SetupView(
                              secret: _setupSecret ?? '',
                              qrDataUrl: _qrDataUrl,
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              onLink: _handleLink,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Setup view ────────────────────────────────────────────────────────────────

class _SetupView extends StatefulWidget {
  final String secret;
  final String? qrDataUrl;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onLink;

  const _SetupView({
    required this.secret,
    required this.qrDataUrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onLink,
  });

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _codeController = TextEditingController();
  bool _copied = false;

  void _copySecret() {
    Clipboard.setData(ClipboardData(text: widget.secret));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        _StepLabel(number: '1', label: t('Scan the QR Code')),
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
              child: _QrView(dataUrl: widget.qrDataUrl),
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
                Text(
                  widget.secret,
                  style: AppTextStyles.settingsItem(
                    context,
                  ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
                ),
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

        _StepLabel(number: '2', label: t('Enter the 6-digit code')),
        const SizedBox(height: 12),
        Text(
          t('Open your authenticator app and enter the code shown.'),
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: 12),

        _OtpCodeField(controller: _codeController),

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

        _PrimaryButton(
          label: t('Verify & Link'),
          isLoading: widget.isLoading,
          onTap: () => widget.onLink(_codeController.text),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── QR view: renders a data:image/png;base64,... URL from the backend ──────

class _QrView extends StatelessWidget {
  final String? dataUrl;
  const _QrView({required this.dataUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 160,
      height: 160,
      color: AppColors.border(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.qr_code_2_rounded,
        size: 80,
        color: AppColors.subtext(context),
      ),
    );

    if (dataUrl == null) return placeholder;

    // Backend returns 'data:image/png;base64,<...>'
    final comma = dataUrl!.indexOf(',');
    if (comma < 0) return placeholder;
    try {
      final bytes = base64Decode(dataUrl!.substring(comma + 1));
      return Image.memory(
        bytes,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    } catch (_) {
      return placeholder;
    }
  }
}

// ── Linked view ───────────────────────────────────────────────────────────────

class _LinkedView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onUnlink;

  const _LinkedView({required this.isLoading, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Column(
      children: [
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                t('Authentication App Linked'),
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
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
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Authenticator App'),
                      style: AppTextStyles.bodyLarge(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('Active • Added Jun 2024'),
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        GestureDetector(
          onTap: isLoading ? null : onUnlink,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.error,
                    ),
                  )
                : Text(
                    t('Remove Authentication App'),
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: AppColors.error,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            gradient: AppColors.purpleGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyLarge(context)),
      ],
    );
  }
}

class _OtpCodeField extends StatelessWidget {
  final TextEditingController controller;
  const _OtpCodeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: AppTextStyles.bookingId(context).copyWith(letterSpacing: 8),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: AppTextStyles.bodyLarge(
          context,
        ).copyWith(letterSpacing: 8, color: AppColors.subtext(context)),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryPurple,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.purpleGradient,
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

// ── Top Bar — matches SecurityPage exactly ────────────────────────────────────

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
                // ✅ Same tokens as SecurityPage — looks identical in dark mode
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
