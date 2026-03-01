import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'settings_models.dart';
import 'appearance.dart';
import '../profile/language/language_page.dart';
import '../../../../main.dart';
import '../../../../l10n/app_localizations.dart';

// ── Profile header card ───────────────────────────────────────────────────────

class ProfileHeaderCard extends StatelessWidget {
  final String name;

  const ProfileHeaderCard({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Avatar(),
        const SizedBox(height: 14),
        Text(name, style: AppTextStyles.profileName(context)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryPurple, width: 2.5),
      ),
      child: ClipOval(
        child: Container(
          color: isDark
              ? const Color(0xFF2A1A3E)
              : const Color(0xFFEDE7F6),
          child: const Icon(
            Icons.person,
            color: AppColors.primaryPurple,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ── Settings section (generic) ────────────────────────────────────────────────

class SettingsSectionWidget extends StatelessWidget {
  final SettingsSection section;
  const SettingsSectionWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(section.label),
        const SizedBox(height: 12),
        Column(
          children: List.generate(section.items.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SettingsRowTile(item: section.items[i]),
            );
          }),
        ),
      ],
    );
  }
}

// ── Settings row tile ─────────────────────────────────────────────────────────

class SettingsRowTile extends StatelessWidget {
  final SettingsItem item;
  const SettingsRowTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isLogout = item.isLogout;

    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLogout
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: isLogout ? AppColors.error : AppColors.primaryPurple,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // ── Title & Subtitle ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.settingsItem(context).copyWith(
                      color: isLogout ? AppColors.error : null,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(item.subtitle!,
                        style: AppTextStyles.bodySmall(context)),
                  ],
                ],
              ),
            ),

            // ── Trailing ──────────────────────────────────────────
            if (item.trailing != null) ...[
              Text(item.trailing!,
                  style: AppTextStyles.settingsItemValue(context)),
              const SizedBox(width: 6),
            ],
            if (!isLogout)
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.subtext(context), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Preferences section ───────────────────────────────────────────────────────

class PreferencesSection extends StatefulWidget {
  const PreferencesSection({super.key});

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  @override
  void initState() {
    super.initState();
    // Listen to both providers so the UI rebuilds on any change
    localeProvider.addListener(_onChanged);
    themeProvider.addListener(_onChanged);
  }

  @override
  void dispose() {
    localeProvider.removeListener(_onChanged);
    themeProvider.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String _themeLabel(BuildContext context) {
    final t = AppLocalizations.of(context);
    return switch (themeProvider.mode) {
      ThemeMode.dark   => t.translate('dark'),
      ThemeMode.light  => t.translate('light'),
      ThemeMode.system => t.translate('system'),
    };
  }

  String _languageLabel() {
    return switch (localeProvider.locale.languageCode) {
      'fr' => 'Français',
      'ar' => 'العربية',
      _    => 'English (US)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(t.translate('preferences')),
        const SizedBox(height: 12),

        // ── Appearance ─────────────────────────────────────────────
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            );
            setState(() {});
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                const _TileIcon(icon: Icons.palette_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(t.translate('appearance'),
                      style: AppTextStyles.settingsItem(context)),
                ),
                Text(_themeLabel(context),
                    style: AppTextStyles.settingsItemValue(context)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.subtext(context), size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Language ───────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguagePage()),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                const _TileIcon(icon: Icons.language_rounded),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(t.translate('language'),
                      style: AppTextStyles.settingsItem(context)),
                ),
                Text(_languageLabel(),
                    style: AppTextStyles.settingsItemValue(context)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.subtext(context), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.iconBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primaryPurple, size: 20),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionLabel(context));
  }
}