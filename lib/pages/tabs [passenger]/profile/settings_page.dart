import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_data.dart';
import 'settings_widgets.dart';
import 'edit_profile/personal_data_page.dart';
import 'notifiaction/notification_page.dart';
import 'settings/settings_sub_page.dart';
import 'saved_places/saved_places_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _tabIndex = 4;

  static const String _userName = 'hamza';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    final sections = buildSettingsSections(
      t: t,
      onPersonalData:   _goToPersonalData,
      onPayments:       () {},
      onSavedPlaces:    _goToSavedPlaces, // ← wired up
      onLogout:         _handleLogout,
      onNotifications:  _goToNotifications,
      onSettings:       _goToSettings,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _TopBar(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 24),
                    ProfileHeaderCard(name: _userName),
                    const SizedBox(height: 28),

                    // Account
                    SettingsSectionWidget(section: sections[0]),
                    const SizedBox(height: 24),

                    // Preferences (Appearance + Language — unchanged)
                    const PreferencesSection(),
                    const SizedBox(height: 24),

                    // Account Management (Notifications + Settings)
                    SettingsSectionWidget(section: sections[1]),
                    const SizedBox(height: 24),

                    // Account Actions (Logout)
                    SettingsSectionWidget(section: sections[2]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            AppTabBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPersonalData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalDataPage()),
    );
  }

  void _goToSavedPlaces() { // ← new method
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPlacesPage()),
    );
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsSubPage()),
    );
  }

  void _handleLogout() {
    final t = AppLocalizations.of(context).translate;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('log_out'), style: AppTextStyles.bodyLarge(context)),
        content: Text(
          t('are_you_sure_logout'),
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'),
                style: AppTextStyles.settingsItemValue(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('log_out'),
                style: AppTextStyles.bodyLarge(context)
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(width: 36, height: 36),
        ),
        Expanded(
          child: Text(
            t('profile'),
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}