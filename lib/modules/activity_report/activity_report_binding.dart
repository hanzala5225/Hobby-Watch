import 'package:get/get.dart';
import 'activity_report_controller.dart';

class ActivityReportBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => ActivityReportController());
}