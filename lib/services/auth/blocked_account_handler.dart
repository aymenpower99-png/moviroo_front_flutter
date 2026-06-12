import 'package:flutter/material.dart';
import '../../main.dart';
import 'auth_storage.dart';

class BlockedAccountException implements Exception {
  final String message;
  BlockedAccountException(this.message);
  @override
  String toString() => message;
}

class AccountBlockedHandler {
  static bool _isShowingDialog = false;

  /// Shows a blocking dialog and forces navigation to login.
  /// Safe to call from anywhere (HTTP interceptors, background checks, etc.).
  static Future<void> showBlockedDialog() async {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    // Clear tokens immediately so no further requests go out
    await AuthStorage.clearTokens();

    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      _isShowingDialog = false;
      return;
    }

    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Account Blocked'),
        content: const Text(
          'Your account has been blocked by an administrator. Please contact support for assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    _isShowingDialog = false;

    // Navigate to login and clear the stack
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}
