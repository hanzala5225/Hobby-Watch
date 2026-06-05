import 'package:get/get.dart';
import 'scan_card_controller.dart';
class ScanCardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => ScanCardController());
}
