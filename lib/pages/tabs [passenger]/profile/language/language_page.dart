import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../main.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth/auth_api.dart';
import '../../../../services/notification_service.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selectedLanguage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = localeProvider.locale.languageCode;
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (_isUpdating) return;

    setState(() {
      _selectedLanguage = languageCode;
      _isUpdating = true;
    });

    try {
      // Update local locale immediately for better UX
      localeProvider.setLocaleByCode(languageCode);

      // Update notification service language
      await NotificationService().setLanguage(languageCode);

      // Sync to backend
      await AuthAPI.updateLanguage(languageCode);

      // Success - navigate back
      if (mounted) {
        Navigator.pop(context, languageCode);
      }
    } catch (e) {
      // Revert local change on error
      localeProvider.setLocaleByCode(localeProvider.locale.languageCode);
      setState(() {
        _selectedLanguage = localeProvider.locale.languageCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final radioBorderColor = isSelected
        ? AppColors.primaryPurple
        : AppColors.subtext(context);

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
                errorBuilder: (_, _, _) => Container(
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
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
