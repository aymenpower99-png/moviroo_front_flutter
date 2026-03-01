import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../main.dart';
import '../../../../l10n/app_localizations.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = localeProvider.locale.languageCode;
  }

  void _selectLanguage(String languageCode) {
    setState(() => _selectedLanguage = languageCode);
    localeProvider.setLocaleByCode(languageCode);
    Navigator.pop(context, languageCode); // ← KEY FIX: pop and return the code
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                      t.translate('language'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 32),

              // ── Section label ────────────────────────────────────
              Text(
                t.translate('selectLanguage'),
                style: AppTextStyles.sectionLabel(context),
              ),
              const SizedBox(height: 12),

              // ── Language options ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    _LanguageTile(
                      flagAsset: 'images/flags/usa.png',
                      label: t.translate('english'),
                      subtitle: t.translate('englishUS'),
                      languageCode: 'en',
                      selected: _selectedLanguage,
                      onTap: () => _selectLanguage('en'),
                    ),
                    Divider(height: 1, indent: 54, color: AppColors.border(context)),
                    _LanguageTile(
                      flagAsset: 'images/flags/france.png',
                      label: t.translate('french'),
                      subtitle: 'Français',
                      languageCode: 'fr',
                      selected: _selectedLanguage,
                      onTap: () => _selectLanguage('fr'),
                    ),
                    Divider(height: 1, indent: 54, color: AppColors.border(context)),
                    _LanguageTile(
                      flagAsset: 'images/flags/saudi.png',
                      label: t.translate('arabic'),
                      subtitle: 'العربية',
                      languageCode: 'ar',
                      selected: _selectedLanguage,
                      onTap: () => _selectLanguage('ar'),
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

// ── Single language tile ──────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String flagAsset;
  final String label;
  final String subtitle;
  final String languageCode;
  final String selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flagAsset,
    required this.label,
    required this.subtitle,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  bool get _isSelected => selected == languageCode;

  @override
  Widget build(BuildContext context) {
    final radioBorderColor =
        _isSelected ? AppColors.primaryPurple : AppColors.subtext(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(flagAsset, width: 34, height: 34, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
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
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioBorderColor, width: 2),
                color: _isSelected ? AppColors.primaryPurple : Colors.transparent,
              ),
              child: _isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}