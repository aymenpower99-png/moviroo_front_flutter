import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../routing/router.dart';
import '../../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late final AnimationController _controller;

  bool _animationDone = false;
  bool _sessionDone = false;
  bool _sessionOk = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _checkSession();
  }

  // 🔐 session check
  Future<void> _checkSession() async {
    try {
      _sessionOk = await _authService.tryRestoreSession();
    } catch (_) {
      _sessionOk = false;
    }

    _sessionDone = true;
    _goNext();
  }

  // 🚀 navigation control
  void _goNext() {
    if (!_animationDone || !_sessionDone) return;
    if (!mounted) return;

    if (_sessionOk) {
      AppRouter.clearAndGo(context, AppRouter.home);
    } else {
      AppRouter.clearAndGo(context, AppRouter.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Lottie.asset(
          'images/splash.json',
          controller: _controller,
          fit: BoxFit.cover,

          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward().then((_) {
                _animationDone = true;
                _goNext();
              });
          },
        ),
      ),
    );
  }
}