import 'package:get/get.dart';
import 'card_detail_controller.dart';
class CardDetailBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => CardDetailController());
}
