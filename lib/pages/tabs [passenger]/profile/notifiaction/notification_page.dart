import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/auth_service/auth_service.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _authService = AuthService();

  bool _pushEnabled = true;
  bool _smsEnabled = false; // local-only — no backend column
  bool _emailEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final response = await _authService.authenticatedGet('/passengers/me');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _pushEnabled = (data['pushNotificationsEnabled'] as bool?) ?? true;
          _emailEnabled = (data['emailNotificationsEnabled'] as bool?) ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePref({bool? push, bool? email}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{};
      if (push != null) body['pushEnabled'] = push;
      if (email != null) body['emailEnabled'] = email;
      await _authService.authenticatedPatch(
        '/passengers/me/notifications',
        body,
      );
    } catch (e) {
      if (!mounted) return;
      // Revert on error
      setState(() {
        if (push != null) _pushEnabled = !push;
        if (email != null) _emailEnabled = !email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('notifications')),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Single notification card ───────────────────
                          _NotificationGroupCard(
                            title: t('notifications'),
                            description: t('notifications_description'),
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            items: [
                              _NotificationToggleItem(
                                label: t('push_notifications'),
                                value: _pushEnabled,
                                onChanged: (v) {
                                  setState(() => _pushEnabled = v);
                                  _updatePref(push: v);
                                },
                              ),
                              _NotificationToggleItem(
                                label: t('sms_messages'),
                                value: _smsEnabled,
                                onChanged: (v) =>
                                    setState(() => _smsEnabled = v),
                              ),
                              _NotificationToggleItem(
                                label: t('email_notifications'),
                                value: _emailEnabled,
                                onChanged: (v) {
                                  setState(() => _emailEnabled = v);
                                  _updatePref(email: v);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification group card ───────────────────────────────────────────────────

class _NotificationGroupCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isDark;
  final List<_NotificationToggleItem> items;

  const _NotificationGroupCard({
    required this.title,
    required this.description,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.settingsItem(context)),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),

          // ── Toggle rows with dividers ──────────────────────
          ...List.generate(items.length, (i) {
            return Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border(context),
                ),
                _ToggleRow(item: items[i], isDark: isDark),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Toggle item data ──────────────────────────────────────────────────────────

class _NotificationToggleItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}

// ── Toggle row widget ─────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final _NotificationToggleItem item;
  final bool isDark;

  const _ToggleRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(item.label, style: AppTextStyles.settingsItem(context)),
          ),
          Switch(
            value: item.value,
            onChanged: item.onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryPurple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark
                ? const Color(0xFF333340)
                : AppColors.lightBorder,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SubPageTopBar extends StatelessWidget {
  final String title;
  const _SubPageTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
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
                size: 22,
                color: AppColors.text(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
