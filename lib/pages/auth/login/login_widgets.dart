import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

InputDecoration fieldDecoration(
  BuildContext context, {
  required String hint,
  required IconData prefixIcon,
  Widget? suffix,
  FocusNode? focusNode,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium(
      context,
    ).copyWith(color: AppColors.subtext(context)),
    prefixIcon: Icon(
      prefixIcon,
      color: focusNode?.hasFocus ?? false
          ? AppColors.primaryPurple
          : AppColors.text(context),
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

Widget label(BuildContext context, String text) => Align(
  alignment: Alignment.centerLeft,
  child: Text(text, style: AppTextStyles.sectionLabel(context)),
);

Widget socialButton({
  required VoidCallback? onPressed,
  required Color backgroundColor,
  required Color borderColor,
  required Widget child,
}) => SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      elevation: 0,
    ),
    child: child,
  ),
);

class LoginWidgets {
  final bool obscurePassword;
  final bool isLoginLoading;
  final bool isGoogleLoading;
  final String? errorMessage;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback togglePassword;
  final Future<void> Function()? onLogin;
  final Future<void> Function()? onGoogleSignIn;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final VoidCallback setState;

  LoginWidgets({
    required this.obscurePassword,
    required this.isLoginLoading,
    required this.isGoogleLoading,
    required this.errorMessage,
    required this.emailController,
    required this.passwordController,
    required this.togglePassword,
    required this.onLogin,
    required this.onGoogleSignIn,
    required this.emailFocus,
    required this.passwordFocus,
    required this.setState,
  });

  Widget buildLogoAndTitle(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── App Logo ──────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'images/lsnn.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 28),

        // ── Title ─────────────────────────────────────────────
        Text(
          t.translate('welcome_back'),
          style: AppTextStyles.pageTitle(
            context,
          ).copyWith(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget buildEmailField(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        label(context, t.translate('label_email_address')),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          focusNode: emailFocus,
          keyboardType: TextInputType.emailAddress,
          onTap: () => setState(),
          decoration: fieldDecoration(
            context,
            hint: t.translate('hint_email'),
            prefixIcon: Icons.email_outlined,
            focusNode: emailFocus,
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        label(context, t.translate('label_password')),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          focusNode: passwordFocus,
          obscureText: obscurePassword,
          onTap: () => setState(),
          decoration: fieldDecoration(
            context,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            focusNode: passwordFocus,
            suffix: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.subtext(context),
              ),
              onPressed: togglePassword,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildForgotPasswordAndError(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── Forgot Password ───────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              t.translate('forgot_password'),
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Error Message ───────────────────────────────────────
        if (errorMessage != null)
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
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildLoginButton(BuildContext context, AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoginLoading ? null : onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          disabledBackgroundColor: AppColors.primaryPurple,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoginLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(t.translate('sign_in'), style: AppTextStyles.buttonPrimary),
      ),
    );
  }

  Widget buildSignUpLink(BuildContext context, AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.translate('no_account'),
          style: AppTextStyles.bodyMedium(context),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
          child: Text(
            t.translate('sign_up'),
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSocialLogin(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        // ── Divider ─────────────────────────────────────────
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border(context))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                t.translate('or_continue_with'),
                style: AppTextStyles.bodySmall(context),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border(context))),
          ],
        ),

        const SizedBox(height: 20),

        // ── Google ────────────────────────────────────────────
        socialButton(
          backgroundColor: AppColors.surface(context),
          borderColor: AppColors.border(context),
          onPressed: isGoogleLoading ? null : onGoogleSignIn,
          child: isGoogleLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.text(context),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/google.png', width: 24, height: 24),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('continue_with_google'),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
