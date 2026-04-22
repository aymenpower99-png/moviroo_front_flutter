import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../routing/router.dart';
import '../../../tabs [passenger]/profile/settings/security/password_page.dart';
import '../../../tabs [passenger]/profile/settings/security/two_step_verification_page.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Security ───────────────────────────────────
                    _SecurityNavTile(
                      title: t('Password'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PasswordPage()),
                      ),
                    ),
                    _SecurityNavTile(
                      title: t('two_factor_authentication'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TwoStepVerificationPage(),
                        ),
                      ),
                    ),
                    _SecurityNavTile(
                      title: t('passkeys'),
                      onTap: () {
                        // TODO: navigate to passkeys page
                      },
                    ),
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
    final t = AppLocalizations.of(context).translate;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('delete_account'),
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.error),
        ),
        content: Text(
          t('delete_account_confirm'),
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.subtext(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Call delete account API
              await AuthService().logout();
              if (context.mounted) {
                AppRouter.clearAndGo(context, AppRouter.login);
              }
            },
            child: Text(
              t('delete'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
