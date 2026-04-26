import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../widgets/password_strength_indicator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Phone number is required');
      return;
    }

    if (phone.length != 8 || !RegExp(r'^\d{8}$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Enter a valid 8-digit Tunisian number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: '+216$phone',
      );

      if (mounted) {
        // Navigate to email verification pending page
        Navigator.pushReplacementNamed(
          context,
          '/check-email',
          arguments: {'email': email},
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    Widget? prefix,
    FocusNode? focusNode,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium(
        context,
      ).copyWith(color: AppColors.subtext(context)),
      prefixIcon:
          prefix ??
          Icon(
            prefixIcon,
            color: focusNode?.hasFocus ?? false
                ? AppColors.primaryPurple
                : AppColors.text(context),
          ),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface(context),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with back button ───────────────────────────────
            Padding(
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
                        color: AppColors.text(context),
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    _buildLogoAndTitle(context, t),

                    const SizedBox(height: 36),

                    _buildNameFields(context, t),

                    const SizedBox(height: 20),

                    _buildEmailField(context, t),

                    const SizedBox(height: 20),

                    _buildPhoneField(context, t),

                    const SizedBox(height: 20),

                    _buildPasswordField(context, t),

                    const SizedBox(height: 32),

                    _buildErrorAndButton(context, t),

                    const SizedBox(height: 24),

                    _buildSignInLink(context, t),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: AppTextStyles.sectionLabel(context)),
  );

  Widget _buildLogoAndTitle(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── Logo ──────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'images/lsnn.png',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 28),

        // ── Title ─────────────────────────────────────────────
        Text(
          t.translate('create_account'),
          style: AppTextStyles.pageTitle(
            context,
          ).copyWith(fontSize: 26, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 8),

        Text(
          t.translate('sign_up_subtitle'),
          style: AppTextStyles.bodyMedium(context),
        ),
      ],
    );
  }

  Widget _buildNameFields(BuildContext context, AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, t.translate('label_first_name')),
              const SizedBox(height: 8),
              TextField(
                controller: _firstNameController,
                focusNode: _firstNameFocus,
                textCapitalization: TextCapitalization.words,
                onTap: () => setState(() {}),
                decoration: _fieldDecoration(
                  context,
                  hint: 'John',
                  prefixIcon: Icons.person_outline,
                  focusNode: _firstNameFocus,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, t.translate('label_last_name')),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameController,
                focusNode: _lastNameFocus,
                textCapitalization: TextCapitalization.words,
                onTap: () => setState(() {}),
                decoration: _fieldDecoration(
                  context,
                  hint: 'Doe',
                  prefixIcon: Icons.person_outline,
                  focusNode: _lastNameFocus,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        _label(context, t.translate('label_email_address')),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          onTap: () => setState(() {}),
          decoration: _fieldDecoration(
            context,
            hint: t.translate('hint_email'),
            prefixIcon: Icons.email_outlined,
            focusNode: _emailFocus,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        _label(context, t.translate('label_phone_number')),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          onTap: () => setState(() {}),
          decoration: InputDecoration(
            hintText: '12345678',
            hintStyle: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.subtext(context)),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/flags/tunisia.png',
                    width: 24,
                    height: 16,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+216',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: _phoneFocus.hasFocus
                          ? AppColors.primaryPurple
                          : AppColors.text(context),
                    ),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primaryPurple,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, t.translate('label_password')),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          onTap: () => setState(() {}),
          decoration: _fieldDecoration(
            context,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            focusNode: _passwordFocus,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.subtext(context),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        PasswordStrengthBar(password: _passwordController.text),
        PasswordRequirementsChecklist(password: _passwordController.text),
      ],
    );
  }

  Widget _buildErrorAndButton(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── Error Message ───────────────────────────────────────
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ── Sign Up Button ──────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              disabledBackgroundColor: AppColors.primaryPurple,
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    t.translate('sign_up'),
                    style: AppTextStyles.buttonPrimary,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink(BuildContext context, AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.translate('have_account'),
          style: AppTextStyles.bodyMedium(context),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text(
            t.translate('sign_in'),
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }
}
