import 'package:flutter/material.dart';
import '../../main.dart';
import '../../routing/router.dart';
import '../auth_service/auth_service.dart';

/// Wraps the entire app and intercepts all user interactions when the account
/// is blocked.  The user stays on the current screen, but the next tap
/// anywhere sends them to the login page.
class BlockedInteractionGuard extends StatelessWidget {
  final Widget child;
  const BlockedInteractionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.isBlocked,
      builder: (context, isBlocked, _) {
        if (!isBlocked) return child;

        return Stack(
          children: [
            AbsorbPointer(absorbing: true, child: child),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _redirectToLogin,
                onPanDown: (_) => _redirectToLogin(),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _redirectToLogin() {
    AuthService.setBlocked(false);
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.login,
      (_) => false,
    );
  }
}
