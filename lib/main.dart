import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/onboarding/onboarding_page.dart';
// import 'pages/auth/auth_page.dart';
// import 'pages/passenger/tabs/passenger_tabs_page.dart';
// import 'pages/driver/tabs/driver_tabs_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B000F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SmartWayApp());
}

class SmartWayApp extends StatefulWidget {
  const SmartWayApp({super.key});

  /// Call this from anywhere to force a full app restart at runtime
  /// (e.g. after logout to clear all state)
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_SmartWayAppState>()?.restartApp();
  }

  @override
  State<SmartWayApp> createState() => _SmartWayAppState();
}

class _SmartWayAppState extends State<SmartWayApp> {
  // Incrementing int key — hot reload preserves state, restartApp() resets it
  int _restartCount = 0;

  void restartApp() {
    setState(() => _restartCount++);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      // Only changes when restartApp() is called — hot reload leaves this intact
      key: ValueKey(_restartCount),
      child: MaterialApp(
        title: 'Smart Way To Travel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (context) => const OnboardingPage(),
          // '/auth':        (context) => const AuthPage(),
          // '/passenger':   (context) => const PassengerTabsPage(),
          // '/driver':      (context) => const DriverTabsPage(),
        },
      ),
    );
  }
}