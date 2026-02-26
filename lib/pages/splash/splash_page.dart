import 'package:flutter/material.dart';
import '../../routing/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Adjust duration to match your GIF length
    await Future.delayed(const Duration(milliseconds: 2460));
    if (!mounted) return;
    AppRouter.clearAndGo(context, AppRouter.onboarding); // or login/home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // match your GIF background
      body: SizedBox.expand(
        child: Image.asset(
          'images/complete.gif',
          fit: BoxFit.cover, // or BoxFit.contain
        ),
      ),
    );
  }
}
