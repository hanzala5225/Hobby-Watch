import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';

/// Handles Firebase Cloud Messaging push notifications.
/// SETUP: Call Get.put(NotificationService()) in main.dart AFTER Firebase.initializeApp()
class NotificationService extends GetxService {
  final _log = Logger();
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initLocalNotifications();
    await _initFirebaseMessaging();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  Future<void> _initFirebaseMessaging() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    _log.i('FCM permission: ${settings.authorizationStatus}');

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _log.i('FCM Token: $token');
      try {
        await Get.find<ApiService>().updateFcmToken(token);
      } catch (e) {
        _log.w('Failed to register FCM token: $e');
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try { await Get.find<ApiService>().updateFcmToken(newToken); } catch (_) {}
    });

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => Get.toNamed('/notifications'));
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'hobby_watch_alerts', 'Hobby Watch Alerts',
      channelDescription: 'Price target alerts for your card collection',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF009286),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Hobby Watch',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
