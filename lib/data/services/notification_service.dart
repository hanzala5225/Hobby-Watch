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
        // Register FCM token with backend. This boot-time attempt can still
        // race ahead of login on a fresh install (no auth token yet, so the
        // save silently 401s) — that's expected. The reliable save point is
        // registerFcmToken() below, called explicitly after login/signup.
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

  // ─── Post-login token registration (the real fix) ─────────────────────────

  /// Re-fetches the current FCM token and saves it to the backend. Call this
  /// right after a successful login AND right after a successful
  /// registration — see login_controller.dart / signup_controller.dart.
  ///
  /// BUG FIX (2026-09): login/signup controllers previously called
  /// `FirebaseMessaging.instance.getToken()` directly, with no wait for the
  /// APNs token first — unlike the boot-time path above, which correctly
  /// waits up to 5s. On a genuinely fresh install (permission just granted,
  /// login submitted almost immediately after), Apple's APNs handshake can
  /// still be mid-flight — getToken() then throws on iOS, and that was
  /// getting silently swallowed by a bare `catch (_) {}` with zero logging,
  /// so this failure was completely invisible. This version waits for APNs
  /// the same way the boot path does, and retries once after a short delay
  /// if it's still not ready, with real logging at every step.
  Future<void> registerFcmToken({int retriesLeft = 1}) async {
    try {
      String? apnsToken;
      try {
        apnsToken = await FirebaseMessaging.instance
            .getAPNSToken()
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
      } catch (e) {
        _log.w('registerFcmToken: getAPNSToken failed: $e');
      }

      if (apnsToken == null) {
        if (retriesLeft > 0) {
          _log.w('registerFcmToken: APNs token not ready yet, retrying in 3s...');
          await Future.delayed(const Duration(seconds: 3));
          return registerFcmToken(retriesLeft: retriesLeft - 1);
        }
        _log.w('registerFcmToken: APNs token still not available after retry — giving up for this session.');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _log.w('registerFcmToken: getToken() returned null');
        return;
      }
      await Get.find<ApiService>().updateFcmToken(token);
      _log.i('FCM token registered post-login: $token');
    } catch (e) {
      _log.w('registerFcmToken failed: $e');
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