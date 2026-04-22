import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../routing/router.dart';
import 'settings_data.dart';
import 'settings_widgets.dart';
import 'edit_profile/personal_data_page.dart';
import 'notifiaction/notification_page.dart';
import 'settings/settings_sub_page.dart';
import 'saved_places/saved_places_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _tabIndex = 4;
  final AuthService _authService = AuthService();

  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _firstName = user['firstName'] ?? '';
          _lastName = user['lastName'] ?? '';
          _phone = user['phone'] ?? '';
          _isLoadingUser = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingUser = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  String get _fullName {
    final name = '$_firstName $_lastName'.trim();
    return name.isNotEmpty ? name : 'User';
  }

  String get _avatarLetter {
    return _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    final sections = buildSettingsSections(
      t: t,
      onPersonalData: _goToPersonalData,
      onPayments: () {},
      onSavedPlaces: _goToSavedPlaces, // ← wired up
      onLogout: _handleLogout,
      onNotifications: _goToNotifications,
      onSettings: _goToSettings,
    );

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
                    _ProfileHeader(
                      letter: _avatarLetter,
                      fullName: _fullName,
                      phone: _phone,
                      isLoading: _isLoadingUser,
                    ),
                    const SizedBox(height: 28),

                    // Account
                    SettingsSectionWidget(section: sections[0]),
                    const SizedBox(height: 24),

                    // Preferences (Appearance + Language — unchanged)
                    const PreferencesSection(),
                    const SizedBox(height: 24),

                    // Account Management (Notifications + Settings)
                    SettingsSectionWidget(section: sections[1]),
                    const SizedBox(height: 24),

                    // Account Actions (Logout)
                    SettingsSectionWidget(section: sections[2]),
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

  void _goToPersonalData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalDataPage()),
    );
  }

  void _goToSavedPlaces() {
    // ← new method
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPlacesPage()),
    );
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsSubPage()),
    );
  }

  void _handleLogout() {
    final t = AppLocalizations.of(context).translate;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('log_out'), style: AppTextStyles.bodyLarge(context)),
        content: Text(
          t('are_you_sure_logout'),
          style: AppTextStyles.bodySmall(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: AppTextStyles.settingsItemValue(context),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                AppRouter.clearAndGo(context, AppRouter.login);
              }
            },
            child: Text(
              t('log_out'),
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(color: AppColors.error),
            ),
          ),
        ],
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
    final t = AppLocalizations.of(context).translate;

    return Row(
      children: [
        GestureDetector(onTap: onBack, child: Container(width: 36, height: 36)),
        Expanded(
          child: Text(
            t('profile'),
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

// ── Profile header with avatar letter ────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String letter;
  final String fullName;
  final String phone;
  final bool isLoading;

  const _ProfileHeader({
    required this.letter,
    required this.fullName,
    required this.phone,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // ── Avatar with first letter ──────────────────────────
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryPurple, width: 2.5),
          ),
          child: ClipOval(
            child: Container(
              color: isDark ? const Color(0xFF2A1A3E) : const Color(0xFFEDE7F6),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(fullName, style: AppTextStyles.profileName(context)),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(phone, style: AppTextStyles.bodySmall(context)),
        ],
      ],
    );
  }
}
