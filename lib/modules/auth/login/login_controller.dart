import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/utils/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/notification_service.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  final _api = Get.find<ApiService>();
  final formKey = GlobalKey<FormState>();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading       = false.obs;
  final obscurePassword = true.obs;

  void togglePassword() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final auth = await _api.login(
        emailController.text.trim(),
        passwordController.text,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAccessToken, auth.accessToken);
      await prefs.setString(AppConstants.keyRefreshToken, auth.refreshToken);
      await prefs.setString(AppConstants.keyUser, jsonEncode(auth.user.toJson()));

      // Now JWT is saved — register FCM token while we have auth.
      // Bug fix (2026-09): this used to call FirebaseMessaging.getToken()
      // directly with no wait for APNs first, which could throw silently on
      // a fresh install (permission just granted, APNs handshake still in
      // flight) and get swallowed by a bare catch, with zero logging.
      // registerFcmToken() waits for APNs and retries once — see
      // notification_service.dart for the full explanation.
      Get.find<NotificationService>().registerFcmToken();

      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar(
        'Login Failed', _parseError(e),
        backgroundColor: const Color(0xFFD63031),
        colorText: const Color(0xFFFFFFFF),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      // No response at all = never reached the server (offline, DNS, or a
      // timeout while a sleeping backend — e.g. Render free tier — wakes up).
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. Please try again in a moment.';
      }
      final status = e.response?.statusCode;
      final serverMessage = e.response?.data is Map ? e.response?.data['message'] : null;
      if (serverMessage is String && serverMessage.isNotEmpty) return serverMessage;
      if (status == 401) return 'Invalid email or password.';
      if (status != null && status >= 500) {
        return 'The server had a problem. Please try again in a moment.';
      }
      return 'Could not connect to server. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}