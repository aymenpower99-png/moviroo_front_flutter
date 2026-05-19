import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service/auth_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../routing/router.dart';

mixin OtpStateMixin<T extends StatefulWidget> on State<T> {
  bool isLoading = false;
  bool isResending = false;
  String? errorMessage;
  String? userId;
  String? purpose;
  String? email;
  String? preAuthToken;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService authService = AuthService();

  void initOtpArgs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          userId = args['userId'] as String?;
          purpose = args['purpose'] as String?;
          email = args['email'] as String?;
          preAuthToken = args['preAuthToken'] as String?;
        });
      }
    });
  }

  void disposeOtp() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
  }

  Future<void> handleVerifyOtp() async {
    final otp = otpControllers.map((c) => c.text).join();
    final t = AppLocalizations.of(context);

    if (otp.length != 6) {
      setState(() => errorMessage = t.translate('otp_enter_6_digits'));
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (purpose == 'verify-email') {
        if (userId == null) {
          setState(() => errorMessage = t.translate('otp_missing_user_id'));
          return;
        }
        await authService.verifyEmail(userId: userId!, code: otp);
        if (mounted) AppRouter.clearAndGo(context, AppRouter.home);
      } else if (purpose == 'login-otp' || purpose == 'login-totp') {
        if (preAuthToken == null || preAuthToken!.isEmpty) {
          setState(() => errorMessage = t.translate('otp_missing_token'));
          return;
        }
        await authService.verifyLoginOtp(
          preAuthToken: preAuthToken!,
          code: otp,
        );
        await authService.getCurrentUser(forceRefresh: true);
        await NotificationService().registerTokenAfterLogin();
        if (mounted) AppRouter.clearAndGo(context, AppRouter.home);
      } else {
        setState(() => errorMessage = t.translate('otp_unknown_purpose'));
      }
    } catch (e) {
      setState(() => errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> handleResend() async {
    if (isResending) return;
    final t = AppLocalizations.of(context);

    setState(() {
      isResending = true;
      errorMessage = null;
    });

    try {
      if (purpose == 'verify-email' && userId != null) {
        await authService.resendVerification(email ?? '');
      } else if (purpose == 'login-otp' && userId != null) {
        await authService.resendLoginOtp(userId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('otp_code_resent'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  void onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    }
  }
}