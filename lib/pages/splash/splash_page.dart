import 'package:flutter/material.dart';
import '../../routing/router.dart';
import '../../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  bool _sessionDone = false;
  bool _sessionOk = false;

  @override
  void initState() {
    super.initState();

    _startApp();
  }

  // 🔐 session check + minimum splash time
  Future<void> _startApp() async {
    final results = await Future.wait([
      _authService.tryRestoreSession(),
      Future.delayed(const Duration(milliseconds: 2800))
    ]);

    if (!mounted) return;

    _sessionOk = results[0] as bool;
    _sessionDone = true;

    _goNext();
  }

  // 🚀 navigation
  void _goNext() {
    if (!_sessionDone) return;
    if (!mounted) return;

    if (_sessionOk) {
      AppRouter.clearAndGo(context, AppRouter.home);
    } else {
      AppRouter.clearAndGo(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SizedBox.expand(
        child: Image.asset(
          'images/complete.gif',
          fit: BoxFit.cover,
          gaplessPlayback: true, // 🔥 prevents GIF restart/flicker
        ),
      ),
    );
  }
}