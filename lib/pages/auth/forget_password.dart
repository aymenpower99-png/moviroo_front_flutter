import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.subtext(context)),
      prefixIcon: Icon(prefixIcon, color: AppColors.text(context), size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(Icons.chevron_left_rounded, color: AppColors.text(context), size: 24),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SECURITY',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionLabel(context),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // ── Icon circle ───────────────────────────────
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.iconBg(context),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3A2A55) : const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: isDark ? 0.25 : 0.12),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.history_rounded, color: AppColors.primaryPurple, size: 38),
                    ),

                    const SizedBox(height: 32),

                    // ── Title ─────────────────────────────────────
                    Text(
                      'Forgot Password?',
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Subtitle ──────────────────────────────────
                    Text(
                      'No worries! Enter your registered email  to\nreceive a secure recovery link.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
                    ),

                    const SizedBox(height: 64),

                    // ── Field label ───────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('ACCOUNT IDENTIFIER', style: AppTextStyles.sectionLabel(context)),
                    ),

                    const SizedBox(height: 8),

                    // ── Input ─────────────────────────────────────
                    TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: AppColors.subtext(context),
                      style: AppTextStyles.bodyMedium(context),
                      decoration: _fieldDecoration(
                        context,
                        hint: 'Email',
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Send Button ───────────────────────────────
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Send Recovery Link', style: AppTextStyles.buttonPrimary),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Sign In link ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Remembered your password? ', style: AppTextStyles.bodyMedium(context)),
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
          ],
        ),
      ),
    );
  }
}