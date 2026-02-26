import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system; // safe default until prefs load

  ThemeMode get mode => _mode;

  ThemeProvider() {
    _load();
  }

  /// Read persisted value on startup.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _mode = _fromString(saved);
    notifyListeners();
  }

  /// Called from AppearancePage when the user picks a theme.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toString(mode));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.dark   => 'dark',
        ThemeMode.light  => 'light',
        ThemeMode.system => 'system',
      };

  static ThemeMode _fromString(String? value) => switch (value) {
        'dark'  => ThemeMode.dark,
        'light' => ThemeMode.light,
        _       => ThemeMode.system, // default for null / unknown
      };
}