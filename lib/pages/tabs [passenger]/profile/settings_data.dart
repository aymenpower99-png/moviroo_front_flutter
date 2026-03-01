import 'package:flutter/material.dart';
import 'settings_models.dart';

List<SettingsSection> buildSettingsSections({
  required String Function(String) t,
  required VoidCallback onPersonalData,
  required VoidCallback onPayments,
  required VoidCallback onSavedPlaces,
  required VoidCallback onLogout,
  required VoidCallback onNotifications,
  required VoidCallback onSettings,
}) {
  return [
    // ── Account ───────────────────────────────────────────────────────────────
    SettingsSection(
      label: t('account'),
      items: [
        SettingsItem(
          icon: Icons.person_outline_rounded,
          title: t('personal_data'),
          onTap: onPersonalData,
        ),
        SettingsItem(
          icon: Icons.place_outlined,
          title: t('saved_places'),
          onTap: onSavedPlaces,
        ),
      ],
    ),

    // ── Preferences ───────────────────────────────────────────────────────────
    SettingsSection(
      label: t('preferences'),
      items: [
        SettingsItem(
          icon: Icons.notifications_none_rounded,
          title: t('notifications'),
          onTap: onNotifications,
        ),
        SettingsItem(
          icon: Icons.settings_outlined,
          title: t('settings'),
          onTap: onSettings,
        ),
      ],
    ),

    // ── Account Actions ───────────────────────────────────────────────────────
    SettingsSection(
      label: t('account_actions'),
      items: [
        SettingsItem(
          icon: Icons.logout_rounded,
          title: t('log_out'),
          isLogout: true,
          onTap: onLogout,
        ),
      ],
    ),
  ];
}