import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/utils/app_constants.dart';
import '../../data/services/notification_service.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      // Safety net for returning users: if their FCM token never saved
      // originally (e.g. they were affected by the pre-fix bug and haven't
      // logged out/in since), this gives them another chance without
      // needing to re-login. Cheap — registerFcmToken() no-ops quickly if
      // the token's already saved and unchanged server-side isn't checked,
      // it just re-sends, which is harmless.
      Get.find<NotificationService>().registerFcmToken();
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}