import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

class SettingsSubPage extends StatefulWidget {
  const SettingsSubPage({super.key});

  @override
  State<SettingsSubPage> createState() => _SettingsSubPageState();
}

class _SettingsSubPageState extends State<SettingsSubPage> {
  // Security
  bool _biometrics = true;
  bool _twoFactor = false;

  // Currency
  String _selectedCurrency = 'USD';

  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar',        'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro',              'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound',     'symbol': '£'},
    {'code': 'TND', 'name': 'Tunisian Dinar',    'symbol': 'TND'},
    {'code': 'MAD', 'name': 'Moroccan Dirham',   'symbol': 'MAD'},
    {'code': 'DZD', 'name': 'Algerian Dinar',    'symbol': 'DZD'},
    {'code': 'SAR', 'name': 'Saudi Riyal',       'symbol': 'SAR'},
    {'code': 'AED', 'name': 'UAE Dirham',        'symbol': 'AED'},
  ];

  void _showCurrencyPicker(BuildContext context, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(t('select_currency'),
                  style: AppTextStyles.bodyLarge(context)),
              const SizedBox(height: 16),
              ..._currencies.map((c) {
                final isSelected = c['code'] == _selectedCurrency;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCurrency = c['code']!);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPurple.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPurple.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            c['symbol']!,
                            style: AppTextStyles.settingsItem(context).copyWith(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : null,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${c['code']} — ${c['name']}',
                            style: AppTextStyles.settingsItem(context),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded,
                              color: AppColors.primaryPurple, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('settings')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Security ───────────────────────────────────
                    _SectionLabel(t('security')),
                    const SizedBox(height: 12),

                    _SwitchTile(
                      icon: Icons.fingerprint_rounded,
                      title: t('biometric_login'),
                      subtitle: t('biometric_login_subtitle'),
                      value: _biometrics,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _biometrics = v),
                    ),
                    const SizedBox(height: 10),
                    _SwitchTile(
                      icon: Icons.security_rounded,
                      title: t('two_factor_auth'),
                      subtitle: t('two_factor_auth_subtitle'),
                      value: _twoFactor,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _twoFactor = v),
                    ),
                    const SizedBox(height: 10),
                    _NavTile(
                      icon: Icons.lock_outline_rounded,
                      title: t('change_password'),
                      subtitle: t('change_password_subtitle'),
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // ── Payment ────────────────────────────────────
                    _SectionLabel(t('payment')),
                    const SizedBox(height: 12),

                    _NavTile(
                      icon: Icons.credit_card_rounded,
                      title: t('payment_methods'),
                      subtitle: t('payment_methods_subtitle'),
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _NavTile(
                      icon: Icons.receipt_long_outlined,
                      title: t('billing_history'),
                      subtitle: t('billing_history_subtitle'),
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _NavTile(
                      icon: Icons.account_balance_outlined,
                      title: t('bank_accounts'),
                      subtitle: t('bank_accounts_subtitle'),
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // ── Currency ───────────────────────────────────
                    _SectionLabel(t('currency')),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => _showCurrencyPicker(context, t),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border(context)),
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
                              child: Center(
                                child: Text(
                                  currency['symbol']!,
                                  style:
                                      AppTextStyles.settingsItem(context)
                                          .copyWith(
                                    color: AppColors.primaryPurple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t('display_currency'),
                                      style: AppTextStyles.settingsItem(
                                          context)),
                                  const SizedBox(height: 2),
                                  Text(currency['name']!,
                                      style: AppTextStyles.bodySmall(
                                          context)),
                                ],
                              ),
                            ),
                            Text(
                              currency['code']!,
                              style: AppTextStyles.settingsItemValue(context),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded,
                                color: AppColors.subtext(context), size: 20),
                          ],
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

// ── Nav tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
            Icon(Icons.chevron_right_rounded,
                color: AppColors.subtext(context), size: 20),
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