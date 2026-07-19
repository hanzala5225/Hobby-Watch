import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/utils/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final _api = Get.find<ApiService>();
  final formKey         = GlobalKey<FormState>();
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();
  final isLoading       = false.obs;
  final obscurePassword  = true.obs;
  final acceptedTerms    = false.obs;

  void togglePassword() => obscurePassword.value = !obscurePassword.value;
  void toggleTerms()    => acceptedTerms.value = !acceptedTerms.value;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (!acceptedTerms.value) {
      Get.snackbar('Terms Required', 'Please accept the Terms & Privacy Policy.',
          backgroundColor: const Color(0xFFE17055), colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
    isLoading.value = true;
    try {
      final auth = await _api.register(
        emailController.text.trim(),
        passwordController.text,
        nameController.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAccessToken, auth.accessToken);
      await prefs.setString(AppConstants.keyRefreshToken, auth.refreshToken);
      await prefs.setString(AppConstants.keyUser, jsonEncode(auth.user.toJson()));

      // JWT is now saved — register FCM token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _api.updateFcmToken(fcmToken);
        }
      } catch (_) {} // non-fatal

      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar('Registration Failed', _parseError(e),
          backgroundColor: const Color(0xFFD63031), colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. It may be waking up — please try again in a moment.';
      }
      final status = e.response?.statusCode;
      final serverMessage = e.response?.data is Map ? e.response?.data['message'] : null;
      if (serverMessage is String && serverMessage.isNotEmpty) return serverMessage;
      if (status != null && status >= 500) {
        return 'The server had a problem. Please try again in a moment.';
      }
      return 'Registration failed.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}