import 'package:get/get.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';

class SoldHistoryController extends GetxController {
  final _api = Get.find<ApiService>();

  final soldCards  = <CardModel>[].obs;
  final isLoading  = true.obs;

  // Lifetime stats calculated from sold cards
  double get totalInvested   => soldCards.fold(0, (s, c) => s + c.purchasePrice);
  double get totalSoldFor    => soldCards.fold(0, (s, c) => s + (c.soldPrice ?? 0));
  double get totalProfit     => totalSoldFor - totalInvested;
  double get avgMargin {
    if (soldCards.isEmpty) return 0;
    final margins = soldCards
        .where((c) => c.soldPrice != null)
        .map((c) {
      final afterFees = (c.soldPrice ?? 0) * (1 - c.ebayFeePercent / 100);
      return ((afterFees - c.purchasePrice) / c.purchasePrice) * 100;
    }).toList();
    if (margins.isEmpty) return 0;
    return margins.reduce((a, b) => a + b) / margins.length;
  }

  @override
  void onInit() {
    super.onInit();
    loadSoldCards();
  }

  Future<void> loadSoldCards() async {
    isLoading.value = true;
    try {
      final result = await _api.getCards(pageSize: 200, includeSold: true);
      soldCards.assignAll(result.cards
        ..sort((a, b) => (b.soldAt ?? DateTime(0)).compareTo(a.soldAt ?? DateTime(0))));
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }
}