import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

class TwoStepVerificationPage extends StatefulWidget {
  const TwoStepVerificationPage({super.key});

  @override
  State<TwoStepVerificationPage> createState() =>
      _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  bool _emailEnabled = false;
  bool _appEnabled = false;
  bool _isLoading = false;

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // TODO: real API call
    if (mounted) setState(() => _isLoading = false);
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Info banner ──
                    _InfoBanner(
                      text: t(
                        '2-step verification adds an extra layer of security to your account by requiring a second form of verification when you sign in.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section label ──
                    Text(
                      t('VERIFICATION METHODS').toUpperCase(),
                      style: AppTextStyles.sectionLabel(context),
                    ),
                    const SizedBox(height: 12),

                    // ── Email ──
                    _VerificationMethodTile(
                      icon: Icons.mail_outline_rounded,
                      title: t('Email'),
                      subtitle: t('Receive a code to your registered email address'),
                      enabled: _emailEnabled,
                      onToggle: (val) => setState(() => _emailEnabled = val),
                    ),
                    const SizedBox(height: 10),

                    // ── Auth App ──
                    _VerificationMethodTile(
                      icon: Icons.phonelink_lock_rounded,
                      title: t('Authentication App'),
                      subtitle: t('Use an authenticator app to generate codes'),
                      enabled: _appEnabled,
                      onToggle: (val) => setState(() => _appEnabled = val),
                    ),

                    const SizedBox(height: 32),

                    // ── Save button ──
                    _PrimaryButton(
                      label: t('Save Changes'),
                      isLoading: _isLoading,
                      onTap: _handleSave,
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
          const Icon(Icons.shield_outlined,
              size: 18, color: AppColors.primaryPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: AppColors.primaryPurple),
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
  final ValueChanged<bool> onToggle;

  const _VerificationMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
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
      child: Row(
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
                Text(title, style: AppTextStyles.bodyLarge(context)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PurpleSwitch(value: enabled, onChanged: onToggle),
        ],
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
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────

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
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label, style: AppTextStyles.buttonPrimary),
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
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.subtext(context)),
            ),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context)),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}