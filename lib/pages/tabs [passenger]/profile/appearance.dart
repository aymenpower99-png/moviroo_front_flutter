import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  ThemeMode get _selected => themeProvider.mode;

  void _select(ThemeMode mode) {
    themeProvider.setMode(mode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top bar ──────────────────────────────────────────
              Row(
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
                        color: AppColors.text(context),
                        size: 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('appearance'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 32),

              // ── Section label ────────────────────────────────────
              Text(t('theme'), style: AppTextStyles.sectionLabel(context)),
              const SizedBox(height: 12),

              // ── Option tiles ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    _ThemeTile(
                      icon: Icons.dark_mode_rounded,
                      label: t('dark'),
                      subtitle: t('dark_subtitle'),
                      mode: ThemeMode.dark,
                      selected: _selected,
                      onTap: () => _select(ThemeMode.dark),
                    ),
                    Divider(
                      height: 1,
                      indent: 54,
                      color: AppColors.border(context),
                    ),
                    _ThemeTile(
                      icon: Icons.light_mode_rounded,
                      label: t('light'),
                      subtitle: t('light_subtitle'),
                      mode: ThemeMode.light,
                      selected: _selected,
                      onTap: () => _select(ThemeMode.light),
                    ),
                    Divider(
                      height: 1,
                      indent: 54,
                      color: AppColors.border(context),
                    ),
                    _ThemeTile(
                      icon: Icons.settings_suggest_rounded,
                      label: t('system'),
                      subtitle: t('system_subtitle'),
                      mode: ThemeMode.system,
                      selected: _selected,
                      onTap: () => _select(ThemeMode.system),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single option tile ────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  bool get _isSelected => selected == mode;

  @override
  Widget build(BuildContext context) {
    final iconBg = _isSelected
        ? AppColors.iconBg(context)
        : AppColors.iconBg(context).withValues(alpha: 0.4);

    final iconColor = _isSelected
        ? AppColors.primaryPurple
        : AppColors.primaryPurple.withValues(alpha: 0.4);

    final radioBorderColor = _isSelected
        ? AppColors.primaryPurple
        : AppColors.subtext(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.settingsItem(context)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall(context)),
                ],
              ),
            ),

            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioBorderColor, width: 2),
                color: _isSelected
                    ? AppColors.primaryPurple
                    : Colors.transparent,
              ),
              child: _isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}