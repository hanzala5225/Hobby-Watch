import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final _api = Get.find<ApiService>();

  final formKey            = GlobalKey<FormState>();
  final emailController    = TextEditingController();
  final newPassController  = TextEditingController();
  final confirmController  = TextEditingController();

  final isLoading     = false.obs;
  final obscureNew    = true.obs;
  final obscureConfirm = true.obs;

  // No email verification in phase 1 — user just enters email + new password
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      await _api.resetPassword(
        emailController.text.trim(),
        newPassController.text,
      );
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        '✅ Password Updated',
        'Your password has been changed. Please sign in.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      String msg = 'Could not reset password.';
      try { msg = (e as dynamic).response?.data['message'] ?? msg; } catch (_) {}
      Get.snackbar('Error', msg,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    newPassController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}