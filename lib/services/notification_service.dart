import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background messages
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

// Top-level function to handle notification response when app is in background
@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  debugPrint('Background notification response: ${details.payload}');
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Instance variables
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Android notification channel details
  static const String _androidChannelId = 'daily_word_channel';
  static const String _androidChannelName = 'Palavras Diárias';
  static const String _androidChannelDescription = 'Notificações sobre novas palavras diárias';

  // iOS notification categories
  static const String _iosCategoryPlain = 'plainCategory';

  /// Initialize the notification service
  Future<void> initialize() async {
    // If already initialized, return immediately
    if (_isInitialized) {
      debugPrint('NotificationService: already initialized');
      return;
    }

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('NotificationService: Firebase not initialized, initializing now');
        await Firebase.initializeApp();
      }

      // Set up handlers for background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize platform-specific settings
      await _initPlatformSpecificSettings();

      // Request notification permissions
      await _requestPermissions();

      // Set up handlers for foreground and opened app notifications
      _setupNotificationHandlers();

      // Subscribe to the daily word topic
      await _subscribeToTopics();

      _isInitialized = true;
      debugPrint('NotificationService: initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: initialization error: $e');
      // Mark as initialized anyway to prevent repeated initialization attempts
      _isInitialized = true;
    }
  }

  /// Initialize platform-specific notification settings
  Future<void> _initPlatformSpecificSettings() async {
    // Android initialization settings
    final AndroidInitializationSettings androidSettings =
    const AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request permissions separately
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategoryPlain,
          actions: [
            DarwinNotificationAction.plain('open', 'Open'),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    // Combined initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the local notifications plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }
  }

  /// Create the notification channel for Android
  Future<void> _createAndroidNotificationChannel() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      showBadge: true,
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request permissions for notifications
  Future<void> _requestPermissions() async {
    // Request permissions for Firebase Messaging
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
      carPlay: false,
    );

    debugPrint('NotificationService: Firebase permission status: ${settings.authorizationStatus}');

    // Request permissions for local notifications on iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // For Android 13+ (API 33+), we need to request permission for local notifications
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // This is only needed for Android 13+
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Set up handlers for foreground and opened app notifications
  void _setupNotificationHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
  }

  /// Subscribe to notification topics
  Future<void> _subscribeToTopics() async {
    try {
      // Check user preferences for notification opt-in
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (notificationsEnabled) {
        await _messaging.subscribeToTopic('daily_word');
        debugPrint('NotificationService: subscribed to daily_word topic');
      } else {
        await _messaging.unsubscribeFromTopic('daily_word');
        debugPrint('NotificationService: unsubscribed from daily_word topic');
      }
    } catch (e) {
      debugPrint('NotificationService: error subscribing to topics: $e');
    }
  }

  /// Toggle notifications on/off
  Future<bool> toggleNotifications(bool enable) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enable);

      if (enable) {
        await _messaging.subscribeToTopic('daily_word');
      } else {
        await _messaging.unsubscribeFromTopic('daily_word');
      }

      debugPrint('NotificationService: notifications ${enable ? 'enabled' : 'disabled'}');
      return true;
    } catch (e) {
      debugPrint('NotificationService: error toggling notifications: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      debugPrint('NotificationService: error checking notification status: $e');
      return true; // Default to enabled
    }
  }

  /// Handle messages that arrive when the app is in the foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: foreground message received: ${message.messageId}');

    try {
      final notification = message.notification;
      final data = message.data;

      // Only show notification if notification payload is available
      if (notification != null) {
        final androidNotification = notification.android;
        final iosNotification = notification.apple;

        // Generate a unique notification ID
        final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

        // Configure platform-specific notification details
        final androidDetails = AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: androidNotification?.smallIcon ?? '@mipmap/ic_launcher',
          channelShowBadge: true,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _iosCategoryPlain,
          threadIdentifier: 'daily_word',
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Show the notification
        _localNotifications.show(
          id,
          notification.title,
          notification.body,
          notificationDetails,
          payload: data.isNotEmpty ? data.toString() : null,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: error displaying foreground notification: $e');
    }
  }

  /// Handle when a notification is tapped and the app is opened
  void _handleNotificationOpened(RemoteMessage message) {
    debugPrint('NotificationService: app opened from notification');

    try {
      final data = message.data;

      // Set a flag to indicate the app was opened from a notification
      if (data.containsKey('type') && data['type'] == 'daily_word') {
        _setOpenedFromNotification();
      }
    } catch (e) {
      debugPrint('NotificationService: error handling notification tap: $e');
    }
  }

  /// Handle notification response when the app is in the foreground
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('NotificationService: notification response: ${response.actionId}');

    try {
      final payload = response.payload;
      if (payload != null && payload.contains('daily_word')) {
        _setOpenedFromNotification();
      }
    } catch (e) {
      debugPrint('NotificationService: error handling notification response: $e');
    }
  }

  /// Set flag that the app was opened from a notification
  Future<void> _setOpenedFromNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('open_from_notification', true);
      debugPrint('NotificationService: set open_from_notification flag');
    } catch (e) {
      debugPrint('NotificationService: error setting notification flag: $e');
    }
  }

  /// Check if the app was opened from a notification
  Future<bool> wasOpenedFromNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasOpened = prefs.getBool('open_from_notification') ?? false;

      // Reset the flag after checking
      if (wasOpened) {
        await prefs.setBool('open_from_notification', false);
      }

      return wasOpened;
    } catch (e) {
      debugPrint('NotificationService: error checking notification open status: $e');
      return false;
    }
  }

  /// Send a test notification (useful for debugging)
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Generate a unique notification ID
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Configure platform-specific notification details
      final androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: _iosCategoryPlain,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _localNotifications.show(
        id,
        'Teste de Notificação',
        'Esta é uma notificação de teste',
        notificationDetails,
        payload: '{"type":"test"}',
      );

      debugPrint('NotificationService: test notification sent');
    } catch (e) {
      debugPrint('NotificationService: error sending test notification: $e');
    }
  }

  /// Get the FCM token for the device
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('NotificationService: error getting FCM token: $e');
      return null;
    }
  }
}
