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
          title: t('Account '),
          subtitle: t('Personal Details'),
          onTap: onPersonalData,
        ),
        SettingsItem(
          icon: Icons.credit_card_rounded,
          title: t('payments'),
          subtitle: t('payments_subtitle'),
          trailing: t('manage'),
          onTap: onPayments,
        ),
        SettingsItem(
          icon: Icons.place_outlined,
          title: t('saved_places'),
          subtitle: t('saved_places_subtitle'),
          onTap: onSavedPlaces,
        ),
      ],
    ),

    // ── Account Management ────────────────────────────────────────────────────
    SettingsSection(
      label: t('ACCOUNT MANAGMENT'),
      items: [
        SettingsItem(
          icon: Icons.notifications_none_rounded,
          title: t('notifications'),
          onTap: onNotifications,
        ),
        SettingsItem(
          icon: Icons.settings_outlined,
          title: t('Settings'),
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