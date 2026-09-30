import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'mobile_auth_service.dart';
import 'smart_alert_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await FcmService.instance.handleBackgroundMessage(message);
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  MobileAuthService? _authService;
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  void setAuthService(MobileAuthService authService) {
    _authService = authService;
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      unawaited(_authService!.updatePushToken(_fcmToken!));
    }
  }

  Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    MobileAuthService? authService,
  }) async {
    if (kIsWeb) return;
    if (_initialized) return;

    if (navigatorKey != null) _navigatorKey = navigatorKey;
    if (authService != null) _authService = authService;

    try {
      final messaging = FirebaseMessaging.instance;

      // Request push permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'FcmService: User granted permission: ${settings.authorizationStatus}',
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen to notification clicks that opened the app from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check cold-start initial message
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Retrieve FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('FcmService: FCM Token obtained: $_fcmToken');
        if (_fcmToken != null && _authService != null) {
          await _authService!.updatePushToken(_fcmToken!);
        }
      } catch (tokenErr) {
        debugPrint('FcmService: Failed to retrieve FCM token: $tokenErr');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FcmService: FCM Token refreshed: $newToken');
        if (_authService != null) {
          unawaited(_authService!.updatePushToken(newToken));
        }
      });

      _initialized = true;
      debugPrint('FcmService: Initialized successfully');
    } catch (e, stack) {
      debugPrint('FcmService: Initialization error: $e\n$stack');
    }
  }

  Future<void> syncToken() async {
    if (kIsWeb) return;
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        _fcmToken = await FirebaseMessaging.instance.getToken();
      }
      if (_fcmToken != null && _authService != null) {
        await _authService!.updatePushToken(_fcmToken!);
      }
    } catch (e) {
      debugPrint('FcmService: syncToken error: $e');
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('FcmService: Background message received: ${message.messageId}');
    await _showNotificationFromMessage(message, isBackground: true);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FcmService: Foreground message received: ${message.messageId}');
    unawaited(_showNotificationFromMessage(message, isBackground: false));
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FcmService: App opened from message: ${message.messageId}');
    _navigateFromPayload(message.data);
  }

  Future<void> _showNotificationFromMessage(
    RemoteMessage message, {
    required bool isBackground,
  }) async {
    try {
      final data = message.data;
      final notification = message.notification;

      final type = data['type']?.toString() ?? 'scheduled_task_reminder';
      final title = data['title']?.toString() ??
          notification?.title ??
          'FLORAPRISE TASK REMINDER';
      final body = data['body']?.toString() ??
          notification?.body ??
          'Scheduled task requires attention';
      final taskIdStr = data['taskId']?.toString() ??
          data['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}';

      final notificationId =
          (int.tryParse(taskIdStr) ?? taskIdStr.hashCode).abs() % 100000;

      final payload = jsonEncode({
        'taskId': taskIdStr,
        'type': type,
        'companyId': data['companyId']?.toString(),
        'source': 'fcm',
      });

      final notificationDetails = SmartAlertNotificationService.instance
          .getTaskReminderNotificationDetails(enableVibration: true);

      await SmartAlertNotificationService.instance.notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint(
        'FcmService: Presented notification $notificationId for task $taskIdStr',
      );
    } catch (e, stack) {
      debugPrint('FcmService: Error presenting notification: $e\n$stack');
    }
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'scheduled_task_reminder' ||
        data.containsKey('taskId') ||
        data.containsKey('cloudId')) {
      _navigateToScheduler();
    }
  }

  void _navigateToScheduler() {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed('/scheduler');
    }
  }
}
