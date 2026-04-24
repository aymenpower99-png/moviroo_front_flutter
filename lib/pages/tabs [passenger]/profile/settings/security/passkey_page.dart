import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/passkey/passkey_service.dart';
import '../../../../../services/auth_service/auth_service.dart';

class PasskeyPage extends StatefulWidget {
  const PasskeyPage({super.key});

  @override
  State<PasskeyPage> createState() => _PasskeyPageState();
}

class _PasskeyPageState extends State<PasskeyPage> {
  final _passkey = PasskeyService();
  final _auth = AuthService();

  bool _isBusy = false;
  bool _isSupported = true;
  bool _alreadyEnabled = false;
  String _methodLabel = 'Device PIN';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final supported = await _passkey.isSupported();
    final label = await _passkey.availableMethodLabel();
    // Always fetch fresh user data so passkeyEnabled is accurate
    final user = await _auth.getCurrentUser(forceRefresh: true);
    final alreadyEnabled = (user?['passkeyEnabled'] as bool?) ?? false;
    if (!mounted) return;
    setState(() {
      _isSupported = supported;
      _methodLabel = label;
      _alreadyEnabled = alreadyEnabled;
    });
  }

  Future<void> _handleEnable() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final result = await _passkey.enable(
      localizedReason:
          'Confirm your identity to enable passkey on this device.',
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isBusy = false;
        _errorMessage = result.errorMessage;
      });
      return;
    }
    // Refresh user data to reflect updated passkeyEnabled flag
    await _auth.getCurrentUser(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _alreadyEnabled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passkey enabled on this device.')),
    );
    Navigator.of(context).maybePop(true);
  }

  Future<void> _handleDisable() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await _passkey.disable();
      if (!mounted) return;
      // Refresh user data to reflect updated passkeyEnabled flag
      await _auth.getCurrentUser(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _alreadyEnabled = false;
        _isBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Close button (top-left) ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main content (scroll-free) ───────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── Smaller circle icon ───────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1C1C22)
                            : const Color(0xFFF5F5F7),
                        border: Border.all(
                          color: AppColors.primaryPurple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.manage_accounts_rounded,
                        color: AppColors.primaryPurple,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Title ─────────────────────────────────────────
                    Text(
                      _alreadyEnabled
                          ? 'Passkey is enabled'
                          : t('create_a_passkey'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 8),

                    // ── Subtitle ──────────────────────────────────────
                    Text(
                      _isSupported
                          ? (_alreadyEnabled
                                ? 'This device will prompt $_methodLabel before sensitive actions.'
                                : t('passkey_subtitle'))
                          : 'This device does not support biometric or device PIN authentication.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
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
                      const SizedBox(height: 12),
                    ],

                    // ── Feature list ──────────────────────────────────
                    _PasskeyFeature(
                      icon: Icons.face_rounded,
                      title: t('passkey_face_unlock'),
                      subtitle: t('passkey_face_unlock_sub'),
                    ),
                    const SizedBox(height: 16),
                    _PasskeyFeature(
                      icon: Icons.fingerprint_rounded,
                      title: t('passkey_fingerprint_unlock'),
                      subtitle: t('passkey_fingerprint_unlock_sub'),
                    ),
                    const SizedBox(height: 16),
                    _PasskeyFeature(
                      icon: Icons.pin_rounded,
                      title: t('passkey_device_pin'),
                      subtitle: t('passkey_device_pin_sub'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom actions (pinned) ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: !_isSupported || _isBusy
                          ? null
                          : (_alreadyEnabled ? _handleDisable : _handleEnable),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _alreadyEnabled
                            ? AppColors.error
                            : AppColors.primaryPurple,
                        disabledBackgroundColor: AppColors.primaryPurple
                            .withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _alreadyEnabled
                                  ? 'Disable Passkey'
                                  : t('create_passkey'),
                              style: AppTextStyles.buttonPrimary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text(
                      _alreadyEnabled ? 'Close' : t('not_now'),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtext(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature list item
// ─────────────────────────────────────────────────────────────────────────────

class _PasskeyFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PasskeyFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg(context),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.settingsItem(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.subtext(context), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
