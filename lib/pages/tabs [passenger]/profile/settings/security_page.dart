import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

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

                    _SecurityNavTile(
                      title: t('Password'),
                      onTap: () {
                        // TODO: Navigate to PasswordPage
                      },
                    ),
                    _SecurityNavTile(
                      title: t('Authentication App'),
                      onTap: () {
                        // TODO: Navigate to AuthAppPage
                      },
                    ),
                    _SecurityNavTile(
                      title: t('2-Step Verification'),
                      onTap: () {
                        // TODO: Navigate to TwoStepPage
                      },
                    ),
                    _SecurityNavTile(
                      title: t('Payment Methods'),
                      onTap: () {
                        // TODO: Navigate to PaymentMethodPage
                      },
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

// ── Simple nav tile — title + chevron, no icon, no subtitle ──────────────────

class _SecurityNavTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SecurityNavTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(title, style: AppTextStyles.settingsItem(context)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.subtext(context),
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
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.subtext(context),
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