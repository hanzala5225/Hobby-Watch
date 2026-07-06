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
  }

  // ─── Firebase Messaging Setup ─────────────────────────────────────────────

  Future<void> _initFirebaseMessaging() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log.i('FCM permission: ${settings.authorizationStatus}');

    // Register FCM token with backend
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _log.i('FCM Token: $token');
      try {
        await Get.find<ApiService>().updateFcmToken(token);
      } catch (e) {
        _log.w('Failed to register FCM token: $e');
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