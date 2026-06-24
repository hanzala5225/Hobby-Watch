import 'package:get/get.dart';
import 'sold_history_controller.dart';
class SoldHistoryBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SoldHistoryController());
}