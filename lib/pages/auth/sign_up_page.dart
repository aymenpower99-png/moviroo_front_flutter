import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();
  final _passwordController  = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.subtext(context)),
      prefixIcon: Icon(prefixIcon, color: AppColors.text(context), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryPurple : const Color(0xFFD1D5DB),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ── Logo ──────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('images/lsnn.png', width: 100, height: 100, fit: BoxFit.cover),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────
              Text(
                'Create Account',
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text('Sign up to get started', style: AppTextStyles.bodyMedium(context)),

              const SizedBox(height: 36),

              // ── First Name & Last Name ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context, 'FIRST NAME'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _firstNameController,
                          cursorColor: AppColors.subtext(context),
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium(context),
                          decoration: _fieldDecoration(context, hint: 'John', prefixIcon: Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context, 'LAST NAME'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _lastNameController,
                          cursorColor: AppColors.subtext(context),
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium(context),
                          decoration: _fieldDecoration(context, hint: 'Doe', prefixIcon: Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Email ─────────────────────────────────────────────
              _label(context, 'EMAIL ADDRESS'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.subtext(context),
                style: AppTextStyles.bodyMedium(context),
                decoration: _fieldDecoration(context, hint: 'name@email.com', prefixIcon: Icons.email_outlined),
              ),

              const SizedBox(height: 20),

              // ── Phone ─────────────────────────────────────────────
              _label(context, 'PHONE NUMBER'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                cursorColor: AppColors.subtext(context),
                style: AppTextStyles.bodyMedium(context),
                decoration: _fieldDecoration(context, hint: '+1 (555) 000-0000', prefixIcon: Icons.phone_outlined),
              ),

              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────────
              _label(context, 'PASSWORD'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                cursorColor: AppColors.subtext(context),
                style: AppTextStyles.bodyMedium(context),
                decoration: _fieldDecoration(
                  context,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.text(context),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Sign Up Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Sign Up', style: AppTextStyles.buttonPrimary),
                ),
              ),

              const SizedBox(height: 24),

              // ── Already have an account? ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTextStyles.bodyMedium(context)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Sign In',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: AppTextStyles.sectionLabel(context)),
      );
}