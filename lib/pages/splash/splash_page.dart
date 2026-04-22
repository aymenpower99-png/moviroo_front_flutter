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

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Run session check in parallel with minimum splash duration
    final results = await Future.wait([
      _authService.tryRestoreSession(),
      Future.delayed(const Duration(seconds: 2), () => null),
    ]);

    if (!mounted) return;

    final bool sessionRestored = results[0] as bool;

    if (sessionRestored) {
      AppRouter.clearAndGo(context, AppRouter.home);
    } else {
      AppRouter.clearAndGo(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset('images/complete.gif', fit: BoxFit.cover),
      ),
    );
  }
}
