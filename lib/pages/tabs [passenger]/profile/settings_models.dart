import 'package:flutter/material.dart';

class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

class SettingsSection {
  final String label;
  final List<SettingsItem> items;

  const SettingsSection({required this.label, required this.items});
}