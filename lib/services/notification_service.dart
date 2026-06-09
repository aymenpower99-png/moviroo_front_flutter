import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service/auth_service.dart';

/// Payload callback when user taps a notification.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class NotificationService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  bool _initialized = false;
  String? _pendingToken; // holds token until login registers it
  String _currentLanguage = 'en'; // default language
  Map<String, String> _translations = {};

  bool get initialized => _initialized;

  /// Called when user taps a notification (foreground / background / terminated).
  NotificationTapCallback? onNotificationTap;

  /// Set the current language and load translations
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    _currentLanguage = languageCode;
    try {
      final jsonStr = await rootBundle.loadString(
        'data/translations/$languageCode.json',
      );
      final Map<String, dynamic> data = json.decode(jsonStr);
      _translations = data.map((k, v) => MapEntry(k, v.toString()));
      debugPrint('🔔 Loaded translations for language: $languageCode');
    } catch (e) {
      debugPrint('❌ Failed to load translations for $languageCode: $e');
    }
  }

  /// Get localized string for a key
  String _translate(String key) => _translations[key] ?? key;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔔 Starting notification service initialization...');

      await _requestPermission();
      await _initializeLocalNotifications();

      debugPrint('🔔 Getting FCM token...');
      final token = await _messaging.getToken();
      debugPrint('🔔 FCM token: ${token?.substring(0, 20) ?? "null"}...');

      if (token != null) {
        // Do NOT register here — user may not be logged in yet.
        _pendingToken = token;
      } else {
        debugPrint('❌ FCM token is null');
      }

      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM token refreshed');
        _pendingToken = newToken;
        _registerToken(newToken);
      });

      // Allow foreground notifications to be presented by the system (iOS + Android)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      // Handle app launched from terminated state via notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App launched from terminated via notification');
        _handleMessageOpened(initialMessage);
      }

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  /// Call this AFTER the user successfully logs in.
  /// Registers the stored FCM token with the backend.
  Future<void> registerTokenAfterLogin() async {
    if (_pendingToken != null) {
      await _registerToken(_pendingToken!);
    } else {
      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ iOS notification permission granted');
      } else {
        debugPrint('❌ iOS notification permission denied');
      }
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('✅ Android notification permission granted');
      } else {
        debugPrint('❌ Android notification permission denied');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_stat_notification');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = _parsePayload(response.payload!);
            onNotificationTap?.call(data);
          } catch (e) {
            debugPrint('❌ Failed to parse notification payload: $e');
          }
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'moviroo_channel',
      'Moviroo Notifications',
      description: 'Moviroo ride notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel rideOffersChannel =
        AndroidNotificationChannel(
          'ride_offers',
          'Ride Offers',
          description: 'Ride offer and ride status notifications',
          importance: Importance.high,
        );

    const AndroidNotificationChannel supportChannel =
        AndroidNotificationChannel(
          'support_messages',
          'Support Messages',
          description: 'Support ticket replies and updates',
          importance: Importance.high,
        );

    const AndroidNotificationChannel rideUpdatesChannel =
        AndroidNotificationChannel(
          'ride_updates',
          'Ride Updates',
          description: 'Live updates for your active ride',
          importance: Importance.high,
        );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(rideOffersChannel);
    await androidPlugin?.createNotificationChannel(supportChannel);
    await androidPlugin?.createNotificationChannel(rideUpdatesChannel);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _authService.authenticatedPost('/notifications/fcm-token', {
        'token': token,
      });
      debugPrint(
        '✅ FCM token registered with backend: ${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '📩 Foreground message received: ${message.notification?.title}',
    );

    final notification = message.notification;
    final notificationType = message.data['type']?.toString() ?? '';
    final channelId = message.data['channelId']?.toString() ?? 'ride_offers';

    // Use localized strings if available, otherwise use FCM provided strings
    String title = notification?.title ?? 'Moviroo';
    String body = notification?.body ?? '';

    // Map notification type to localized keys
    if (notificationType.isNotEmpty && _translations.isNotEmpty) {
      String translationKey = notificationType.toLowerCase();

      // Special handling for RIDE_STATUS_CHANGED with status field
      if (notificationType == 'RIDE_STATUS_CHANGED') {
        final status = message.data['status']?.toString() ?? '';
        if (status.isNotEmpty) {
          translationKey = 'ride_status_${status.toLowerCase()}';
        }
      }

      title = _translate('notif_${translationKey}_title');

      // For chat/reply types, keep the actual message text as body
      // (the FCM body contains the real reply content from the sender)
      if (notificationType == 'SUPPORT_TICKET_REPLY' ||
          notificationType == 'CHAT_MESSAGE') {
        // body already set from FCM notification above — keep it
      } else {
        body = _translate('notif_${translationKey}_body');
      }
    }

    final channelName = switch (channelId) {
      'support_messages' => 'Support Messages',
      'ride_offers' => 'Ride Offers',
      'ride_updates' => 'Ride Updates',
      _ => 'Moviroo Notifications',
    };
    final channelDesc = switch (channelId) {
      'support_messages' => 'Support ticket replies and updates',
      'ride_offers' => 'Ride offer and ride status notifications',
      'ride_updates' => 'Live updates for your active ride',
      _ => 'Moviroo ride notifications',
    };

    if (notification != null || (title.isNotEmpty && body.isNotEmpty)) {
      await _localNotifications.show(
        notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_stat_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_notification_large',
            ),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _handleMessageOpened(RemoteMessage message) async {
    debugPrint('📩 Message opened: ${message.data}');
    if (message.data.isNotEmpty) {
      onNotificationTap?.call(message.data);
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      // Fallback for legacy plain-string payloads
      return {'type': payload};
    }
  }

  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('🔔 Current FCM token: ${token?.substring(0, 20) ?? "null"}...');
    return token;
  }

  static Future<String?> testGetToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔔 TEST - FCM token: ${token?.substring(0, 20) ?? "null"}...');
    return token;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }
}
