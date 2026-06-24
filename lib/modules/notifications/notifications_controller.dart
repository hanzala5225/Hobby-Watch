import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class NotificationsController extends GetxController {
  final _api = Get.find<ApiService>();

  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading     = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final n = await _api.getNotifications();
      print('DEBUG notifications count: ${n.length}');
      print('DEBUG first item: ${n.isNotEmpty ? n.first : "empty"}');
      notifications.assignAll(n);
    } catch (e) {
      print('DEBUG loadNotifications ERROR: $e');  // ← see what's failing
    } finally {
      isLoading.value = false;
    }
  }


  /// Mark a single notification as read (tapping the tile).
  /// Updates locally immediately so the UI reacts without a reload.
  Future<void> markRead(String? id) async {
    if (id == null) return;
    try {
      await _api.markNotificationRead(id);
      // Update locally — find the item and flip isRead
      final idx = notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(notifications[idx]);
        updated['isRead'] = true;
        notifications[idx] = updated;
      }
    } catch (_) {}
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      // Update all locally
      notifications.assignAll(
        notifications.map((n) => {...n, 'isRead': true}).toList(),
      );
    } catch (_) {}
  }
}