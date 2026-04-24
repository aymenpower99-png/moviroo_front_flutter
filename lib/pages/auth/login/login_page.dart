import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import 'login_handlers.dart';
import 'login_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  bool get _isAnyLoading => _isLoginLoading || _isGoogleLoading;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _setError(String? msg) => _errorMessage = msg;
  void _setLoginLoading(bool loading) => _isLoginLoading = loading;
  void _setGoogleLoading(bool loading) => _isGoogleLoading = loading;

  void _batchSetState(VoidCallback fn) => setState(fn);

  Future<void> _handleLogin() async {
    await handleLogin(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      setError: _setError,
      setLoginLoading: _setLoginLoading,
      batchSetState: _batchSetState,
      authService: _authService,
      context: context,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await handleGoogleSignIn(
      setError: _setError,
      setGoogleLoading: _setGoogleLoading,
      batchSetState: _batchSetState,
      authService: _authService,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final widgets = LoginWidgets(
      obscurePassword: _obscurePassword,
      isLoginLoading: _isLoginLoading,
      isGoogleLoading: _isGoogleLoading,
      errorMessage: _errorMessage,
      emailController: _emailController,
      passwordController: _passwordController,
      togglePassword: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onLogin: _isAnyLoading ? null : _handleLogin,
      onGoogleSignIn: _isAnyLoading ? null : _handleGoogleSignIn,
      emailFocus: _emailFocus,
      passwordFocus: _passwordFocus,
      setState: () => setState(() {}),
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  widgets.buildLogoAndTitle(context, t),
                  const SizedBox(height: 40),
                  widgets.buildEmailField(context, t),
                  const SizedBox(height: 20),
                  widgets.buildPasswordField(context, t),
                  const SizedBox(height: 1),
                  widgets.buildForgotPasswordAndError(context, t),
                  const SizedBox(height: 0),
                  widgets.buildLoginButton(context, t),
                  const SizedBox(height: 8),
                  widgets.buildSignUpLink(context, t),
                  const SizedBox(height: 20),
                  widgets.buildSocialLogin(context, t),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isAnyLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.translate('loading'),
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
