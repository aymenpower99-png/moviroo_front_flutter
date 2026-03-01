import 'package:flutter/material.dart';
import '../pages/onboarding/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/sign_up_page.dart';
import '../pages/auth/forget_password.dart';
import '../pages/tabs [passenger]/home/home_page.dart';
import '../pages/tabs [passenger]/support/support_page.dart';
import '../pages/tabs [passenger]/profile/settings_page.dart';
import '../pages/tabs [passenger]/trajet/trajet_page.dart';
import '../pages/tabs [passenger]/membre/membre_pass_screen.dart';
import '../pages/splash/splash_page.dart';

class AppRouter {
  // ── Route name constants ───────────────────────────────────────────────────
  static const String splash      = '/splash';
  static const String onboarding  = '/onboarding';
  static const String login       = '/login';
  static const String signup      = '/signup';
  static const String forgotPass  = '/forgot-password';
  static const String home        = '/home';
  static const String support     = '/support';
  static const String membre      = '/membre';
  static const String profile     = '/profile';
  static const String driverHome  = '/driver/home';

  // ── Initial route ──────────────────────────────────────────────────────────
  static const String initialRoute = splash;

  // ── Route map ─────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
    splash:     (_) => const SplashPage(),
    onboarding: (_) => const OnboardingPage(),
    login:      (_) => const LoginPage(),
    signup:     (_) => const SignUpPage(),
    forgotPass: (_) => const ForgotPasswordPage(),
    home:       (_) => const HomePage(),
    support:    (_) => const SupportPage(),
    membre:     (_) => const MembrePassScreen(),
    profile:    (_) => const SettingsPage(),
    driverHome: (_) => const TrajetPage(),
  };

  /// Push a named route
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: args);
  }

  /// Replace current route (no back button)
  static Future<T?> replace<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      routeName,
      arguments: args,
    );
  }

  /// Clear the entire stack and go to a route
  static Future<T?> clearAndGo<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (_) => false,
      arguments: args,
    );
  }

  /// Go back
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}