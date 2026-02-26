import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _rideUpdates = true;
  bool _promotions = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('notifications')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Channels ───────────────────────────────────
                    _SectionLabel(t('notification_channels')),
                    const SizedBox(height: 12),

                    _SwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: t('push_notifications'),
                      subtitle: t('push_notifications_subtitle'),
                      value: _pushNotifications,
                      isDark: isDark,
                      onChanged: (v) =>
                          setState(() => _pushNotifications = v),
                    ),
                    const SizedBox(height: 10),
                    _SwitchTile(
                      icon: Icons.email_outlined,
                      title: t('email_notifications'),
                      subtitle: t('email_notifications_subtitle'),
                      value: _emailNotifications,
                      isDark: isDark,
                      onChanged: (v) =>
                          setState(() => _emailNotifications = v),
                    ),
                    const SizedBox(height: 10),
                    _SwitchTile(
                      icon: Icons.sms_outlined,
                      title: t('sms_notifications'),
                      subtitle: t('sms_notifications_subtitle'),
                      value: _smsNotifications,
                      isDark: isDark,
                      onChanged: (v) =>
                          setState(() => _smsNotifications = v),
                    ),
                    const SizedBox(height: 24),

                    // ── Activity ───────────────────────────────────
                    _SectionLabel(t('activity')),
                    const SizedBox(height: 12),

                    _SwitchTile(
                      icon: Icons.directions_car_outlined,
                      title: t('ride_updates'),
                      subtitle: t('ride_updates_subtitle'),
                      value: _rideUpdates,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _rideUpdates = v),
                    ),
                    const SizedBox(height: 10),
                    _SwitchTile(
                      icon: Icons.local_offer_outlined,
                      title: t('promotions'),
                      subtitle: t('promotions_subtitle'),
                      value: _promotions,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _promotions = v),
                    ),
                    const SizedBox(height: 10),
                    _SwitchTile(
                      icon: Icons.volume_up_outlined,
                      title: t('sound'),
                      subtitle: t('sound_subtitle'),
                      value: _soundEnabled,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _soundEnabled = v),
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

// ── Switch tile ───────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.iconBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.settingsItem(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.bodySmall(context)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryPurple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor:
                isDark ? const Color(0xFF333340) : AppColors.lightBorder,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.sectionLabel(context));
}

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
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.subtext(context),
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