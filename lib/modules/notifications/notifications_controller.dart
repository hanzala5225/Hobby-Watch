import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class NotificationsController extends GetxController {
  final _api = Get.find<ApiService>();
  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() { super.onInit(); loadNotifications(); }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final n = await _api.getNotifications();
      notifications.assignAll(n);
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    try { await _api.markAllNotificationsRead(); await loadNotifications(); } catch (_) {}
  }
}
