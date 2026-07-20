import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';

class NotificationService extends GetxService {
  final _log = Logger();
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initLocalNotifications();
    await _initFirebaseMessaging();
  }

  // ─── Local Notifications Setup ────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        Get.toNamed('/notifications');
      },
    );

    // Android 13+ (API 33+) requires explicitly requesting POST_NOTIFICATIONS
    // at runtime. Without this, foreground local notifications (like the
    // target-reached alert shown via _showLocalNotification) can silently
    // fail to display even though FCM itself delivers the message
    // successfully — background/system-tray notifications aren't affected
    // by this since Android shows those itself without app code.
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      _log.w('Android notification permission request failed: $e');
    }
  }

  // ─── Firebase Messaging Setup ─────────────────────────────────────────────

  Future<void> _initFirebaseMessaging() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _log.i('FCM permission: ${settings.authorizationStatus}');

      // On iOS, getToken() requires an APNs token to exist first. On Simulator
      // it never arrives; on a real device it can occasionally be slow on cold
      // launch. Wait for it with a timeout instead of calling getToken() blind —
      // that's what was causing the unhandled apns-token-not-set crash.
      String? apnsToken;
      try {
        apnsToken = await FirebaseMessaging.instance
            .getAPNSToken()
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
      } catch (e) {
        _log.w('getAPNSToken failed: $e');
      }

      if (apnsToken == null) {
        _log.w('APNs token not available (expected on Simulator) — skipping FCM token fetch.');
      } else {
        // Register FCM token with backend
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            _log.i('FCM Token: $token');
            try {
              await Get.find<ApiService>().updateFcmToken(token);
            } catch (e) {
              _log.w('Failed to register FCM token: $e');
            }
          }
        } catch (e) {
          _log.w('getToken failed: $e');
        }
      }

      // Keep token fresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await Get.find<ApiService>().updateFcmToken(newToken);
        } catch (_) {}
      });

      // FOREGROUND: app is open — show banner + save to backend
      FirebaseMessaging.onMessage.listen((message) async {
        await _showLocalNotification(message);
        await _saveToBackend(message);
      });

      // BACKGROUND TAP: user tapped notification while app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        await _saveToBackend(message);
        Get.toNamed('/notifications');
      });

      // COLD START TAP: user tapped notification while app was terminated
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _saveToBackend(initial);
        // Small delay so the app finishes initializing before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        Get.toNamed('/notifications');
      }
    } catch (e) {
      _log.w('Firebase Messaging setup failed: $e');
    }
  }

  // ─── Show Local Banner (foreground only) ─────────────────────────────────

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'hobby_watch_alerts',
      'Hobby Watch Alerts',
      channelDescription: 'Price target alerts for your card collection',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFF009286),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Hobby Watch',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // ─── Save to Backend ──────────────────────────────────────────────────────

  Future<void> _saveToBackend(RemoteMessage message) async {
    final title = message.notification?.title;
    final body  = message.notification?.body;
    if (title == null || title.isEmpty) return;

    try {
      await Get.find<ApiService>().saveReceivedNotification(
        title:        title,
        body:         body ?? '',
        type:         message.data['type'] ?? 'campaign',
        payload:      message.data,
        fcmMessageId: message.messageId,
      );
      _log.d('Notification saved to backend: $title');
    } catch (e) {
      _log.w('Failed to save notification to backend: $e');
    }
  }
}