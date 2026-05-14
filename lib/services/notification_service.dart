import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service/auth_service.dart';

/// Payload callback when user taps a notification.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  bool _initialized = false;
  String? _pendingToken; // holds token until login registers it

  bool get initialized => _initialized;

  /// Called when user taps a notification (foreground / background / terminated).
  NotificationTapCallback? onNotificationTap;

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

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

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

    await (_localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >())
        ?.createNotificationChannel(channel);
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
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'moviroo_channel',
            'Moviroo Notifications',
            channelDescription: 'Moviroo ride notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_stat_notification',
            largeIcon: DrawableResourceAndroidBitmap(
              '@mipmap/ic_notification_large',
            ),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }

    // Also propagate data payload to any listeners
    if (message.data.isNotEmpty) {
      onNotificationTap?.call(message.data);
    }
  }

  Future<void> _handleMessageOpened(RemoteMessage message) async {
    debugPrint('📩 Message opened: ${message.data}');
    if (message.data.isNotEmpty) {
      onNotificationTap?.call(message.data);
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    // payload is currently the .toString() of a Map, e.g.
    // {ride_id: abc123, type: DRIVER_ASSIGNED}
    // We'll do a lightweight parse.
    final result = <String, dynamic>{};
    final clean = payload.replaceAll(RegExp(r'^[^{]*\{|}[^}]*$'), '');
    for (final entry in clean.split(',')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0].trim()] = parts[1].trim();
      }
    }
    return result;
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
