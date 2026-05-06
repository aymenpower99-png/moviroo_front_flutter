import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  bool _initialized = false;

  // Getters
  bool get initialized => _initialized;

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔔 Starting notification service initialization...');

      // Request notification permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      debugPrint('🔔 Getting FCM token...');
      final token = await _messaging.getToken();
      debugPrint('🔔 FCM token: ${token?.substring(0, 20) ?? "null"}...');

      if (token != null) {
        await _registerToken(token);
      } else {
        debugPrint('❌ FCM token is null');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM token refreshed');
        _registerToken(newToken);
      });

      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Configure background message handling
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  /// Request notification permission from user
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
      // Android 13+ needs POST_NOTIFICATIONS permission
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('✅ Android notification permission granted');
      } else {
        debugPrint('❌ Android notification permission denied');
      }
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await _localNotifications.initialize(initializationSettings);

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Register FCM token with backend
  Future<void> _registerToken(String token) async {
    try {
      final response = await _authService.authenticatedPost(
        '/notifications/fcm-token',
        {'token': token},
      );
      debugPrint(
        '✅ FCM token registered with backend: ${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
    }
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '📩 Foreground message received: ${message.notification?.title}',
    );

    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle message when user taps on notification
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    debugPrint('📩 Message opened: ${message.data}');
    // Handle navigation based on message data
    // For example: navigate to ride details, chat, etc.
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('🔔 Current FCM token: ${token?.substring(0, 20) ?? "null"}...');
    return token;
  }

  /// Test method to check if service is working
  static Future<String?> testGetToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔔 TEST - FCM token: ${token?.substring(0, 20) ?? "null"}...');
    return token;
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }
}
