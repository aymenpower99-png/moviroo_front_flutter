import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../widgets/password_strength_indicator.dart';
import '../../../../../services/auth_service/auth_service.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _authService = AuthService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;
  String? _serverError;

  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUppercase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase =>
      _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _allRulesMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial;

  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text &&
      _confirmPasswordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentPasswordController.text.isNotEmpty &&
      _allRulesMet &&
      _passwordsMatch;

  Future<void> _handleSave() async {
    if (!_canSubmit) return;
    setState(() {
      _isLoading = true;
      _serverError = null;
    });
    try {
      await _authService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('password_updated_success'),
          ),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _serverError = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final bool newHasText = _newPasswordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('password_page_title')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Section label ──
                    Text(
                      t('change_password'),
                      style: AppTextStyles.sectionLabel(context),
                    ),
                    const SizedBox(height: 16),

                    // ── Current Password ──
                    _PasswordField(
                      controller: _currentPasswordController,
                      label: t('current_password'),
                      obscure: _currentObscure,
                      onToggle: () =>
                          setState(() => _currentObscure = !_currentObscure),
                      hasError: _serverError != null,
                    ),
                    const SizedBox(height: 16),

                    // ── New Password ──
                    _PasswordField(
                      controller: _newPasswordController,
                      label: t('new_password'),
                      obscure: _newObscure,
                      onToggle: () =>
                          setState(() => _newObscure = !_newObscure),
                      hasError: newHasText && !_allRulesMet,
                    ),

                    PasswordStrengthBar(password: _newPasswordController.text),

                    if (newHasText && !_allRulesMet) ...[
                      const SizedBox(height: 6),
                      Text(
                        t('password_rules_error'),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.error),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Password rules checklist ──
                    _PasswordRules(
                      hasMinLength: _hasMinLength,
                      hasUppercase: _hasUppercase,
                      hasLowercase: _hasLowercase,
                      hasSpecial: _hasSpecial,
                      hasNumber: _hasNumber,
                    ),

                    const SizedBox(height: 16),

                    // ── Confirm New Password ──
                    _PasswordField(
                      controller: _confirmPasswordController,
                      label: t('confirm_new_password'),
                      obscure: _confirmObscure,
                      onToggle: () =>
                          setState(() => _confirmObscure = !_confirmObscure),
                      hasError:
                          _confirmPasswordController.text.isNotEmpty &&
                          !_passwordsMatch,
                    ),

                    if (_confirmPasswordController.text.isNotEmpty &&
                        !_passwordsMatch) ...[
                      const SizedBox(height: 6),
                      Text(
                        t('passwords_no_match'),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.error),
                      ),
                    ],

                    if (_serverError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serverError!,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Save Button ──
                    _PrimaryButton(
                      label: t('change_password_btn'),
                      isLoading: _isLoading,
                      enabled: _canSubmit,
                      onTap: _handleSave,
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

// ── Password Rules Checklist ──────────────────────────────────────────────────

class _PasswordRules extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasSpecial;
  final bool hasNumber;

  const _PasswordRules({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasSpecial,
    required this.hasNumber,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          _RuleRow(met: hasMinLength, label: t('rule_min_length')),
          const SizedBox(height: 6),
          _RuleRow(met: hasUppercase, label: t('rule_uppercase')),
          const SizedBox(height: 6),
          _RuleRow(met: hasLowercase, label: t('rule_lowercase')),
          const SizedBox(height: 6),
          _RuleRow(met: hasSpecial, label: t('rule_special')),
          const SizedBox(height: 6),
          _RuleRow(met: hasNumber, label: t('rule_number')),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final bool met;
  final String label;

  const _RuleRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.subtext(context);

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: color,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Password Field ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final bool hasError;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall(context)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.settingsItem(context),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border(context),
              ),
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 22,
                color: AppColors.text(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isLoading || !enabled) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.purpleGradient : null,
          color: enabled ? null : AppColors.border(context),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.buttonPrimary.copyWith(
                  color: enabled ? Colors.white : AppColors.subtext(context),
                ),
              ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

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
