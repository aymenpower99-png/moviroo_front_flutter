import 'package:flutter/material.dart';
import 'settings_models.dart';

List<SettingsSection> buildSettingsSections({
  required VoidCallback onPersonalData,
  required VoidCallback onPayments,
  required VoidCallback onSavedPlaces,
  required VoidCallback onLogout,
}) {
  return [
    SettingsSection(
      label: 'ACCOUNT',
      items: [
        SettingsItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal data',
          subtitle: 'Name, phone number, email',
          onTap: onPersonalData,
        ),
        SettingsItem(
          icon: Icons.credit_card_rounded,
          title: 'Payments',
          subtitle: 'Visa ••42 as default',
          trailing: 'Manage',
          onTap: onPayments,
        ),
        SettingsItem(
          icon: Icons.place_outlined,
          title: 'Saved places',
          subtitle: 'Home, Work and more',
          onTap: onSavedPlaces,
        ),
      ],
    ),
    SettingsSection(
      label: 'ACCOUNT ACTIONS',
      items: [
        SettingsItem(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          onTap: onLogout,
        ),
      ],
    ),
  ];
}