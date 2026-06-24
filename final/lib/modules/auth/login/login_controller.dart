import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/utils/app_constants.dart';
import '../../../data/services/api_service.dart';
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

      // Now JWT is saved — register FCM token while we have auth
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _api.updateFcmToken(fcmToken);
        }
      } catch (_) {} // non-fatal

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
    try { return e.response?.data['message'] ?? 'Invalid email or password.'; }
    catch (_) { return 'Could not connect to server. Please check your connection.'; }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}