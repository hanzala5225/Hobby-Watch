import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/utils/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final _api = Get.find<ApiService>();
  final formKey        = GlobalKey<FormState>();
  late final nameController     = TextEditingController();
  late final emailController    = TextEditingController();
  late final passwordController = TextEditingController();
  late final confirmController  = TextEditingController();
  final isLoading       = false.obs;
  final obscurePassword  = true.obs;
  final acceptedTerms    = false.obs;
  bool _disposed = false;

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
    try { return e.response?.data['message'] ?? 'Registration failed.'; }
    catch (_) { return 'Could not connect to server.'; }
  }

  @override
  void onClose() {
    if (!_disposed) {
      _disposed = true;
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      confirmController.dispose();
    }
    super.onClose();
  }
}