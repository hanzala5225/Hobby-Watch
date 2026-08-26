import 'package:get/get.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';

class ActivityReportController extends GetxController {
  final _api = Get.find<ApiService>();

  // Moved off the dashboard (2026-08-26) — Hanzala's call: cramming a
  // filterable report into the dashboard didn't make sense visually and
  // needed real room to grow (e.g. more stats, a future breakdown list).
  // This is an ACTIVITY report for the selected range — cards added/sold
  // within it — not a historical "what was my portfolio worth on day X"
  // reconstruction, since the app doesn't track portfolio value over time.
  // See ActivitySummaryResponse (backend) for the full reasoning.
  final selectedRange     = 'ytd'.obs; // 'month' | 'quarter' | 'year' | 'ytd'
  final activitySummary   = Rx<ActivitySummary?>(null);
  final isLoading         = true.obs;
  final loadFailed        = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  (DateTime, DateTime) _rangeBounds(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
      case 'quarter':
        final qStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(now.year, qStartMonth, 1);
        final end = DateTime(now.year, qStartMonth + 3, 1);
        return (start, end);
      case 'year':
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      case 'ytd':
      default:
      // Year-to-date: Jan 1 through tomorrow (exclusive end), so today is included.
        return (DateTime(now.year, 1, 1), DateTime(now.year, now.month, now.day + 1));
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    loadFailed.value = false;
    try {
      final (start, end) = _rangeBounds(selectedRange.value);
      activitySummary.value = await _api.getActivitySummary(startDate: start, endDate: end);
    } catch (_) {
      loadFailed.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void setRange(String range) {
    if (selectedRange.value == range) return;
    selectedRange.value = range;
    load();
  }
}