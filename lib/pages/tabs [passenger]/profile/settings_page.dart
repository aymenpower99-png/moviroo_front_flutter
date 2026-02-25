import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'settings_data.dart';
import 'settings_models.dart';
import 'settings_widgets.dart';
import 'edit_profile/personal_data_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _tabIndex = 4;

  static const String _userName = 'hamza';

  late final List<SettingsSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = buildSettingsSections(
      onPersonalData: _goToPersonalData,
      onPayments:     () {},
      onSavedPlaces:  () {},
      onLogout:       _handleLogout,
    );
  }

  void _goToPersonalData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalDataPage()),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: AppTextStyles.bodyLarge(context)),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.settingsItemValue(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Log Out',
                style: AppTextStyles.bodyLarge(context)
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    SettingsSectionWidget(section: _sections[0]),
                    const SizedBox(height: 24),
                    const PreferencesSection(),
                    const SizedBox(height: 24),
                    SettingsSectionWidget(section: _sections[1]),
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
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
          ),
        ),
        Expanded(
          child: Text(
            'Profile',
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}