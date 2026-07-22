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

  double get totalProfit {
    return soldCards.fold(0.0, (sum, c) => sum + _afterFees(c) - c.purchasePrice);
  }

  double get avgMargin {
    if (soldCards.isEmpty) return 0;
    final margins = soldCards
        .where((c) => c.soldPrice != null && c.purchasePrice > 0)
        .map((c) => ((_afterFees(c) - c.purchasePrice) / c.purchasePrice) * 100)
        .toList();
    if (margins.isEmpty) return 0;
    return margins.reduce((a, b) => a + b) / margins.length;
  }

  // Shared calc: eBay fee applies to (sold price + shipping) combined, and
  // never applies at all for a sold-outside-eBay sale.
  double _afterFees(CardModel c) {
    final soldPrice = c.soldPrice ?? 0;
    final combined = soldPrice + c.shippingCharge;
    final feePercent = c.soldOutsideEbay ? 0.0 : c.ebayFeePercent;
    return combined * (1 - feePercent / 100);
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