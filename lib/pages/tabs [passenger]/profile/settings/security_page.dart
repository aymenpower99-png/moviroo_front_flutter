import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../tabs [passenger]/profile/settings/security/password_page.dart';
import '../../../tabs [passenger]/profile/settings/security/two_step_verification_page.dart';
import '../../../tabs [passenger]/profile/settings/security/passkey_page.dart';
import 'delete_account_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final AuthService _authService = AuthService();
  String? _authProvider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _authProvider = (user?['authProvider'] as String?)?.toLowerCase();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isGoogleUser => _authProvider == 'google';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('security')),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Password (email users only) ────────────
                          if (!_isGoogleUser)
                            _SecurityNavTile(
                              title: t('Password'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PasswordPage(),
                                ),
                              ),
                            ),

                          // ── Two-Factor Authentication (all users) ──
                          _SecurityNavTile(
                            title: t('two_factor_authentication'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TwoStepVerificationPage(),
                              ),
                            ),
                          ),

                          // ── Passkeys (all users) ────────────────────
                          _SecurityNavTile(
                            title: t('passkeys'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PasskeyPage(),
                              ),
                            ),
                          ),

                          // ── Delete account (all users) ──────────────
                          _SecurityNavTile(
                            title: t('delete_account'),
                            isDestructive: true,
                            onTap: () => _confirmDeleteAccount(context),
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

  void _confirmDeleteAccount(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DeleteAccountPage()));
  }
}

// ── Simple nav tile — title + chevron, no icon, no subtitle ──────────────────

class _SecurityNavTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SecurityNavTile({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : null;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.settingsItem(
                    context,
                  ).copyWith(color: color),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color ?? AppColors.subtext(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.border(context)),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

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
