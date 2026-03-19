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
    Navigator.pop(context, languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final languages = [
      _LangConfig(
        flagAsset: 'images/flags/usa.png',
        label: t.translate('english'),
        subtitle: 'English (US)',
        code: 'en',
      ),
      _LangConfig(
        flagAsset: 'images/flags/france.png',
        label: t.translate('french'),
        subtitle: 'Français',
        code: 'fr',
      ),
      _LangConfig(
        flagAsset: 'images/flags/saudi.png',
        label: t.translate('arabic'),
        subtitle: 'العربية',
        code: 'ar',
      ),
      _LangConfig(
        flagAsset: 'images/flags/german.png',
        label: t.translate('german'),
        subtitle: 'Deutsch',
        code: 'de',
      ),
      _LangConfig(
        flagAsset: 'images/flags/spain.png',
        label: t.translate('spanish'),
        subtitle: 'Español',
        code: 'es',
      ),
      _LangConfig(
        flagAsset: 'images/flags/italy.png',
        label: t.translate('italian'),
        subtitle: 'Italiano',
        code: 'it',
      ),
      _LangConfig(
        flagAsset: 'images/flags/pt.png',
        label: t.translate('portuguese'),
        subtitle: 'Português',
        code: 'pt',
      ),
      _LangConfig(
        flagAsset: 'images/flags/turkey.png',
        label: t.translate('turkish'),
        subtitle: 'Türkçe',
        code: 'tr',
      ),
      _LangConfig(
        flagAsset: 'images/flags/china.png',
        label: t.translate('chinese'),
        subtitle: '中文',
        code: 'zh',
      ),
      _LangConfig(
        flagAsset: 'images/flags/japan.png',
        label: t.translate('japanese'),
        subtitle: '日本語',
        code: 'ja',
      ),
      _LangConfig(
        flagAsset: 'images/flags/russia.png',
        label: t.translate('russian'),
        subtitle: 'Русский',
        code: 'ru',
      ),
    ];

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

              // ── Language cards — each one standalone ─────────────
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _LanguageCard(
                    flagAsset: languages[i].flagAsset,
                    label: languages[i].label,
                    subtitle: languages[i].subtitle,
                    languageCode: languages[i].code,
                    selected: _selectedLanguage,
                    onTap: () => _selectLanguage(languages[i].code),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal data model ───────────────────────────────────────────────────────

class _LangConfig {
  final String flagAsset;
  final String label;
  final String subtitle;
  final String code;

  const _LangConfig({
    required this.flagAsset,
    required this.label,
    required this.subtitle,
    required this.code,
  });
}

// ── Standalone language card ──────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final String flagAsset;
  final String label;
  final String subtitle;
  final String languageCode;
  final String selected;
  final VoidCallback onTap;

  const _LanguageCard({
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
    final isSelected = _isSelected;
    final radioBorderColor =
        isSelected ? AppColors.primaryPurple : AppColors.subtext(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Flag ─────────────────────────────────────────────
            ClipOval(
              child: Image.asset(
                flagAsset,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.iconBg(context),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: AppColors.subtext(context),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Labels ───────────────────────────────────────────
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

            // ── Radio indicator ───────────────────────────────────
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioBorderColor, width: 2),
                color: isSelected
                    ? AppColors.primaryPurple
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}