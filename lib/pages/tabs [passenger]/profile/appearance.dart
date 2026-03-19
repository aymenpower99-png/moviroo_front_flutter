import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage>
    with SingleTickerProviderStateMixin {
  ThemeMode get _selected => themeProvider.mode;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Subtle slide: starts slightly above, settles into place (top-down feel)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start fully visible
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(ThemeMode mode) async {
    if (_selected == mode) return;

    // 1. Fade + drift upward (out)
    await _controller.reverse();

    // 2. Apply the new theme
    await themeProvider.setMode(mode);
    if (!mounted) return;
    setState(() {});

    // 3. Fade + drift down from top (in)
    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Top bar ──────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.border(context)),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.text(context),
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t('appearance'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.pageTitle(context),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Section label ────────────────────────────────────
                  Text(t('theme'),
                      style: AppTextStyles.sectionLabel(context)),
                  const SizedBox(height: 12),

                  // ── Option tiles ─────────────────────────────────────
                  _ThemeTile(
                    icon: Icons.dark_mode_rounded,
                    label: t('dark'),
                    subtitle: t('dark_subtitle'),
                    mode: ThemeMode.dark,
                    selected: _selected,
                    onTap: () => _select(ThemeMode.dark),
                  ),
                  const SizedBox(height: 10),
                  _ThemeTile(
                    icon: Icons.light_mode_rounded,
                    label: t('light'),
                    subtitle: t('light_subtitle'),
                    mode: ThemeMode.light,
                    selected: _selected,
                    onTap: () => _select(ThemeMode.light),
                  ),
                  const SizedBox(height: 10),
                  _ThemeTile(
                    icon: Icons.settings_suggest_rounded,
                    label: t('system'),
                    subtitle: t('system_subtitle'),
                    mode: ThemeMode.system,
                    selected: _selected,
                    onTap: () => _select(ThemeMode.system),
                    isSystemDark: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single option tile ────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode selected;
  final VoidCallback onTap;
  final bool isSystemDark;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.selected,
    required this.onTap,
    this.isSystemDark = false,
  });

  bool get _isSelected => selected == mode;

  @override
  Widget build(BuildContext context) {
    final iconBg = _isSelected
        ? AppColors.iconBg(context)
        : AppColors.iconBg(context).withValues(alpha: 0.4);

    final iconColor = _isSelected
        ? AppColors.primaryPurple
        : AppColors.primaryPurple.withValues(alpha: 0.4);

    final radioBorderColor =
        _isSelected ? AppColors.primaryPurple : AppColors.subtext(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isSelected
                ? AppColors.primaryPurple
                : AppColors.border(context),
            width: _isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: AppTextStyles.settingsItem(context)),
                        if (isSystemDark) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.iconBg(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Dark',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.primaryPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall(context)),
                  ],
                ),
              ),

              // Radio circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: radioBorderColor, width: 2),
                  color: _isSelected
                      ? AppColors.primaryPurple
                      : Colors.transparent,
                ),
                child: _isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}