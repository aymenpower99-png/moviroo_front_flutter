import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;

  // ── Validation rule states ──
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUppercase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase =>
      _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber =>
      _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPasswordController.text
      .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _allRulesMet =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecial;

  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text &&
      _confirmPasswordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_allRulesMet || !_passwordsMatch) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // TODO: real API call
    if (mounted) setState(() => _isLoading = false);
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
            _SubPageTopBar(title: t('Password')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Section label ──
                    Text(
                      t('CHANGE PASSWORD').toUpperCase(),
                      style: AppTextStyles.sectionLabel(context),
                    ),
                    const SizedBox(height: 16),

                    // ── New Password ──
                    _PasswordField(
                      controller: _newPasswordController,
                      label: t('New Password'),
                      obscure: _newObscure,
                      onToggle: () =>
                          setState(() => _newObscure = !_newObscure),
                      hasError: newHasText && !_allRulesMet,
                    ),

                    // ── Validation error message ──
                    if (newHasText && !_allRulesMet) ...[
                      const SizedBox(height: 6),
                      Text(
                        t('Please add all necessary characters to create a safe password.'),
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.error),
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
                      label: t('Confirm New Password'),
                      obscure: _confirmObscure,
                      onToggle: () =>
                          setState(() => _confirmObscure = !_confirmObscure),
                      hasError: _confirmPasswordController.text.isNotEmpty &&
                          !_passwordsMatch,
                    ),

                    if (_confirmPasswordController.text.isNotEmpty &&
                        !_passwordsMatch) ...[
                      const SizedBox(height: 6),
                      Text(
                        t('Passwords do not match.'),
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.error),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Save Button ──
                    _PrimaryButton(
                      label: t('Change Password'),
                      isLoading: _isLoading,
                      enabled: _allRulesMet && _passwordsMatch,
                      onTap: _handleSave,
                    ),

                    const SizedBox(height: 16),


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
          _RuleRow(met: hasMinLength, label: t('Minimum 8 characters')),
          const SizedBox(height: 6),
          _RuleRow(met: hasUppercase, label: t('One uppercase character')),
          const SizedBox(height: 6),
          _RuleRow(met: hasLowercase, label: t('One lowercase character')),
          const SizedBox(height: 6),
          _RuleRow(met: hasSpecial, label: t('One special character')),
          const SizedBox(height: 6),
          _RuleRow(met: hasNumber, label: t('One number')),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.subtext(context),
                size: 20,
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