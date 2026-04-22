import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../routing/router.dart';

Future<void> handleLogin({
  required String email,
  required String password,
  required Function(String?) setError,
  required Function(bool) setLoginLoading,
  required void Function(VoidCallback) batchSetState,
  required AuthService authService,
  required BuildContext context,
}) async {
  if (email.isEmpty || password.isEmpty) {
    batchSetState(() => setError('Please fill in all fields'));
    return;
  }

  batchSetState(() {
    setLoginLoading(true);
    setError(null);
  });

  try {
    final result = await authService.login(email: email, password: password);

    if (!context.mounted) return;

    // 2FA OTP required — navigate to OTP page with pre-auth token
    if (result['requiresOtp'] == true) {
      final stage = (result['stage'] as String?) ?? 'login-otp';
      final preAuthToken = (result['preAuthToken'] as String?) ?? '';
      final userId = (result['userId'] as String?) ?? '';
      batchSetState(() => setLoginLoading(false));
      Navigator.pushNamed(context, AppRouter.otp, arguments: {
        'purpose': stage,
        'preAuthToken': preAuthToken,
        'userId': userId,
        'email': email,
      });
      return;
    }

    // Email verification required — navigate to OTP page
    if (result['requiresVerification'] == true) {
      final userId = (result['userId'] as String?) ?? '';
      batchSetState(() => setLoginLoading(false));
      Navigator.pushNamed(context, AppRouter.otp, arguments: {
        'purpose': 'verify-email',
        'userId': userId,
        'email': email,
      });
      return;
    }

    // Normal login — pre-cache user data so profile page doesn't refetch
    await authService.getCurrentUser(forceRefresh: true);
    if (context.mounted) {
      AppRouter.clearAndGo(context, AppRouter.home);
    }
  } catch (e) {
    batchSetState(() {
      setError(e.toString().replaceAll('Exception: ', ''));
    });
  } finally {
    if (context.mounted) {
      batchSetState(() => setLoginLoading(false));
    }
  }
}

Future<void> handleGoogleSignIn({
  required Function(String?) setError,
  required Function(bool) setGoogleLoading,
  required void Function(VoidCallback) batchSetState,
  required AuthService authService,
  required BuildContext context,
}) async {
  batchSetState(() {
    setGoogleLoading(true);
    setError(null);
  });

  try {
    await authService.googleSignIn();
    // Pre-cache user data so profile page doesn't refetch
    await authService.getCurrentUser(forceRefresh: true);
    if (context.mounted) {
      AppRouter.clearAndGo(context, AppRouter.home);
    }
  } catch (e) {
    batchSetState(() {
      setError(e.toString().replaceAll('Exception: ', ''));
    });
  } finally {
    if (context.mounted) {
      batchSetState(() => setGoogleLoading(false));
    }
  }
}

Future<void> handleAppleSignIn({
  required Function(String?) setError,
  required Function(bool) setAppleLoading,
  required AuthService authService,
  required BuildContext context,
}) async {
  setAppleLoading(true);
  setError(null);

  try {
    await authService.appleSignIn();
    if (context.mounted) {
      AppRouter.clearAndGo(context, AppRouter.home);
    }
  } catch (e) {
    setError(e.toString().replaceAll('Exception: ', ''));
  } finally {
    if (context.mounted) {
      setAppleLoading(false);
    }
  }
}
