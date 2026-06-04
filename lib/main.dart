import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'core/firebase/firebase_service.dart';
import 'services/auth_service/auth_service.dart';
import 'services/recent_searches/recent_searches_service.dart';
import 'services/notification_service.dart';
import 'providers/booking_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/membership_provider.dart';
import 'services/currency/currency_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/geocoding/geocoding_service.dart' as geocoding_svc;
import 'services/mapbox/mapbox_place.dart' as mapbox_place;
import 'core/utils/address_utils.dart' as address_utils;
import 'services/driver_profile_cache.dart';

final themeProvider = ThemeProvider();
final localeProvider = LocaleProvider();

/// Global navigator key for notification tap navigation from anywhere.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
}

void main() async {
  debugPrint('🚀 App starting...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 🔥 KEEP native splash until we manually remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  debugPrint('🚀 Splash preserved...');

  // Mapbox token
  MapboxOptions.setAccessToken(
    'pk.eyJ1IjoiYXltb3VuMTEiLCJhIjoiY21vM2JvY3UzMGtrdzJzcXc0cXZwbmE5eiJ9.LcnOY7q-WQ37STLy7wogRA',
  );

  // Init Firebase BEFORE anything else
  await FirebaseService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Init notification service (does NOT register token yet — waits for login)
  await NotificationService().initialize();
  await RecentSearchesService.clearOldCache();
  await CurrencyService.instance.init();

  // Initialize flutter_downloader for system DownloadManager
  // Temporarily disabled to debug crash
  // await FlutterDownloader.initialize(
  //   debug: true, // Set to false in production
  // );

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Pre-load driver profile cache from disk so avatars are instant
  await DriverProfileCache.instance.init();

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
    _initNotificationTapHandler();
    _syncAddressLocale();
    localeProvider.addListener(_syncAddressLocale);
  }

  /// Sync the current app locale with address localization utilities.
  void _syncAddressLocale() {
    final code = localeProvider.locale.languageCode;
    geocoding_svc.setAddressLocale(code);
    mapbox_place.setMapboxPlaceLocale(code);
  }

  @override
  void dispose() {
    localeProvider.removeListener(_syncAddressLocale);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initNotificationTapHandler() {
    NotificationService().onNotificationTap = (data) {
      final type = data['type']?.toString() ?? '';
      final rideId = data['rideId']?.toString() ?? '';
      final driverName = data['driverName']?.toString();
      final driverId = data['driverId']?.toString();
      final vehicleName = data['vehicleName']?.toString();
      final vehicleColor = data['vehicleColor']?.toString();
      final plateNumber = data['plateNumber']?.toString();
      final driverPhotoUrl =
          data['driverLogoUrl']?.toString() ??
          data['driverPhotoUrl']?.toString() ??
          data['driver_logo_url']?.toString();

      // Pre-cache driver photo so avatar renders instantly on next screen
      if (driverId != null && driverId.isNotEmpty && driverPhotoUrl != null && driverPhotoUrl.isNotEmpty) {
        DriverProfileCache.instance.set(driverId, {
          'logoUrl': driverPhotoUrl,
          'firstName': driverName,
        });
      }

      debugPrint('🔔 Notification tap — type: $type, rideId: $rideId');

      final nav = navigatorKey.currentState;
      if (nav == null) return;

      switch (type) {
        case 'DRIVER_ASSIGNED':
        case 'DRIVER_ARRIVED':
        case 'RIDE_STARTED':
        case 'RIDE_COMPLETED':
          if (rideId.isNotEmpty) {
            nav.pushNamed(
              AppRouter.trackRide,
              arguments: {
                'rideId': rideId,
                'driverName': driverName ?? 'Driver',
                'driverPhotoUrl': driverPhotoUrl ?? '',
                'vehicleName': vehicleName ?? '',
                'vehicleColor': vehicleColor ?? '',
                'plateNumber': plateNumber ?? '',
              },
            );
          }
          break;
        case 'CHAT_MESSAGE':
          if (rideId.isNotEmpty) {
            nav.pushNamed(
              AppRouter.chat,
              arguments: {
                'rideId': rideId,
                'driverName': driverName ?? 'Driver',
                'driverId': driverId,
                'driverPhotoUrl': driverPhotoUrl,
                'vehicleName': vehicleName ?? '',
                'vehicleColor': vehicleColor ?? '',
                'plateNumber': plateNumber ?? '',
              },
            );
          }
          break;
        case 'SUPPORT_TICKET_REPLY':
        case 'SUPPORT_TICKET_CREATED':
          final ticketId = data['ticketId']?.toString() ?? '';
          if (ticketId.isNotEmpty) {
            nav.pushNamed(
              AppRouter.supportChat,
              arguments: {'ticketId': ticketId},
            );
          }
          break;
        case 'RIDE_CANCELLED':
          nav.pushNamedAndRemoveUntil(AppRouter.trajet, (route) => false);
          break;
        default:
          // Unknown type — fall back to home
          nav.pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
      }
    };
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

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => BookingProvider()),
              ChangeNotifierProvider(create: (_) => ChatProvider()),
              ChangeNotifierProvider(create: (_) => MembershipProvider()),
              ChangeNotifierProvider.value(value: CurrencyService.instance),
            ],
            child: MaterialApp(
              title: 'Moviroo',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.mode,
              navigatorObservers: [appRouteObserver],
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
                Locale('ar'),
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
