import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _NotifCategory {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  bool push;
  bool email;

  _NotifCategory({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    this.push = false,
    this.email = false,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<_NotifCategory> _categories = [
    _NotifCategory(
      icon: Icons.calendar_today_outlined,
      titleKey: 'booking_updates',
      subtitleKey: 'booking_updates_subtitle',
      push: true,
      email: false,
    ),
    _NotifCategory(
      icon: Icons.local_offer_outlined,
      titleKey: 'deals_promotions',
      subtitleKey: 'deals_promotions_subtitle',
      push: true,
      email: true,
    ),
    _NotifCategory(
      icon: Icons.forum_outlined,
      titleKey: 'community_tips',
      subtitleKey: 'community_tips_subtitle',
      push: false,
      email: true,
    ),
  ];

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Column header labels ───────────────────────
                    _ChannelHeaderRow(
                      pushLabel: t('push'),
                      emailLabel: t('email'),
                    ),
                    const SizedBox(height: 10),

                    // ── Category cards ─────────────────────────────
                    ..._categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryCard(
                          icon: cat.icon,
                          title: t(cat.titleKey),
                          subtitle: t(cat.subtitleKey),
                          pushValue: cat.push,
                          emailValue: cat.email,
                          pushLabel: t('push_notifications'),
                          emailLabel: t('email_label'),
                          onPushChanged: (v) =>
                              setState(() => cat.push = v),
                          onEmailChanged: (v) =>
                              setState(() => cat.email = v),
                        ),
                      ),
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

// ── Channel header row ────────────────────────────────────────────────────────

class _ChannelHeaderRow extends StatelessWidget {
  final String pushLabel;
  final String emailLabel;

  const _ChannelHeaderRow({
    required this.pushLabel,
    required this.emailLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42 + 12),
        const Expanded(child: SizedBox()),
        _HeaderLabel(pushLabel),
        const SizedBox(width: 12),
        _HeaderLabel(emailLabel),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.subtext(context),
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool pushValue;
  final bool emailValue;
  final String pushLabel;
  final String emailLabel;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onEmailChanged;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pushValue,
    required this.emailValue,
    required this.pushLabel,
    required this.emailLabel,
    required this.onPushChanged,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category header ──────────────────────────────
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.settingsItem(context)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall(context)),
                  ],
                ),
              ),
            ],
          ),

          // ── Divider ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border(context)),
          ),

          // ── Toggle rows ───────────────────────────────────
          _ToggleRow(
            label: pushLabel,
            value: pushValue,
            isDark: isDark,
            onChanged: onPushChanged,
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            label: emailLabel,
            value: emailValue,
            isDark: isDark,
            onChanged: onEmailChanged,
          ),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.subtext(context),
            ),
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