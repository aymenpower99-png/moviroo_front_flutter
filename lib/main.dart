import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'core/firebase/firebase_service.dart';
import 'services/auth_service/auth_service.dart';
import 'services/recent_searches/recent_searches_service.dart';
import 'providers/booking_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

final themeProvider = ThemeProvider();
final localeProvider = LocaleProvider();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 🔥 KEEP native splash until we manually remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Mapbox token
  MapboxOptions.setAccessToken(
    'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA',
  );

  // Init services BEFORE app start
  await FirebaseService.initialize();
  await RecentSearchesService.clearOldCache();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
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
  StreamSubscription? _linkSubscription;
  final AuthService _authService = AuthService();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );
    }
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;

    if (uri.scheme == 'moviroo' && uri.path == '/auth/callback') {
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        _authService.saveTokens(accessToken, refreshToken);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppRouter.clearAndGo(context, AppRouter.home);
          }
        });
      }
    }
  }

  void restartApp() => setState(() => _restartCount++);

  void _applySystemUI(ThemeMode mode) {
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF0B0B0F)
            : const Color(0xFFF4F4F8),
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_restartCount),
      child: ListenableBuilder(
        listenable: Listenable.merge([themeProvider, localeProvider]),
        builder: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _applySystemUI(themeProvider.mode),
          );

          return ChangeNotifierProvider(
            create: (_) => BookingProvider(),
            child: MaterialApp(
              title: 'Moviroo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.mode,
              navigatorObservers: [appRouteObserver],
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
                Locale('ar'),
                Locale('de'),
                Locale('es'),
                Locale('it'),
                Locale('pt'),
                Locale('tr'),
                Locale('zh'),
                Locale('ru'),
                Locale('ja'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
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
                  pageBuilder: (context, _, _) => builder(context),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
