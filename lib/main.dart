import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/locale_provider.dart';
import 'l10n/app_localizations.dart';

final themeProvider  = ThemeProvider();
final localeProvider = LocaleProvider();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SmartWayApp());
}

class SmartWayApp extends StatefulWidget {
  const SmartWayApp({super.key});

  static void restartApp(BuildContext context) =>
      context.findAncestorStateOfType<_SmartWayAppState>()?.restartApp();

  @override
  State<SmartWayApp> createState() => _SmartWayAppState();
}

class _SmartWayAppState extends State<SmartWayApp> {
  int _restartCount = 0;

  void restartApp() => setState(() => _restartCount++);

  void _applySystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          isDark ? const Color(0xFF0B0B0F) : const Color(0xFFF4F4F8),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_restartCount),
      child: ListenableBuilder(
        listenable: Listenable.merge([themeProvider, localeProvider]),
        builder: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _applySystemUI(themeProvider.mode));

          return MaterialApp(
            title: 'Moviroo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.mode,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
              Locale('ar'), // Arabic (RTL)
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate, // handles RTL automatically
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return supportedLocales.first;
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale.languageCode) {
                  return supported;
                }
              }
              return supportedLocales.first;
            },
            initialRoute: AppRouter.initialRoute,
            onGenerateRoute: (settings) {
              final builder = AppRouter.routes[settings.name];
              if (builder == null) return null;
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, _, __) => builder(context),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            },
          );
        },
      ),
    );
  }
}