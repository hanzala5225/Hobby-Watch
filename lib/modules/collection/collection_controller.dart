import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';
import '../dashboard/dashboard_controller.dart';

class CollectionController extends GetxController {
  final _api = Get.find<ApiService>();
  final cards         = <CardModel>[].obs;
  final summary       = PortfolioSummary.empty().obs;
  final isLoading     = true.obs;
  final searchQuery   = ''.obs;
  final sortBy        = 'created_at'.obs;
  final searchController = TextEditingController();

  // 'all' or 'targetReached' — set from Get.arguments when navigated here
  // via the dashboard's "Ready to Sell" → View all link.
  final filterMode = 'all'.obs;

  List<CardModel> get filteredCards {
    final q = searchQuery.value.toLowerCase();
    var active = cards.where((c) => !c.isSold).toList();
    if (filterMode.value == 'targetReached') {
      active = active.where((c) => c.isTargetReached).toList();
    }
    if (q.isEmpty) return active;
    return active.where((c) =>
    c.playerName.toLowerCase().contains(q) ||
        c.name.toLowerCase().contains(q) ||
        (c.setName?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<CardModel> get soldCards => cards.where((c) => c.isSold).toList();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['filter'] == 'targetReached') {
      filterMode.value = 'targetReached';
    }
    loadCards();
  }

  void onResume() {
    loadCards();
  }

  Future<void> loadCards() async {
    isLoading.value = true;
    try {
      final result = await _api.getCards(sortBy: sortBy.value);
      cards.assignAll(result.cards);
      summary.value = result.summary;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String q) => searchQuery.value = q;

  Future<void> deleteCard(String id) async {
    await _api.deleteCard(id);
    cards.removeWhere((c) => c.id == id);
    // Sync dashboard so it updates instantly without needing a reload
    if (Get.isRegistered<dynamic>(tag: null) || true) {
      try {
        final dashboard = Get.find<DashboardController>();
        dashboard.cards.removeWhere((c) => c.id == id);
        dashboard.cards.refresh();
      } catch (_) {}
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}