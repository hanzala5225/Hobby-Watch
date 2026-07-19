import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/utils/app_constants.dart';
import '../../data/models/auth_model.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';
import '../routes/app_routes.dart';

class DashboardController extends GetxController {
  final _api = Get.find<ApiService>();

  final cards        = <CardModel>[].obs;
  final summary      = PortfolioSummary.empty().obs;
  final isLoading    = true.obs;
  final isRefreshing = false.obs;
  final user         = Rx<UserModel?>(null);

  List<CardModel> get targetReachedCards => cards.where((c) => c.isTargetReached && !c.isSold).toList();
  List<CardModel> get recentCards        => cards.where((c) => !c.isSold).take(5).toList();

  // Called by CardDetailController after marking a card sold — instant UI update
  void updateCardInPlace(CardModel updated) {
    final idx = cards.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;

    if (updated.isSold) {
      // A sold card no longer belongs in the active dashboard list (that's
      // what was causing "My Collection (1)" to stick around after selling —
      // the card was being updated in place instead of removed). Remove it
      // and recompute the summary tiles locally so Portfolio Value / Invested
      // / Cards update instantly, without waiting for a manual refresh.
      final removed = cards[idx];
      cards.removeAt(idx);

      final investedForCard = removed.purchasePrice;
      final valueForCard    = removed.currentEbayAvg30 ?? removed.purchasePrice;
      final newInvested = (summary.value.totalInvested - investedForCard).clamp(0, double.infinity).toDouble();
      final newValue    = (summary.value.totalCurrentValue - valueForCard).clamp(0, double.infinity).toDouble();
      final newPL        = newValue - newInvested;
      final newPLPercent = newInvested > 0 ? (newPL / newInvested) * 100 : 0.0;

      summary.value = PortfolioSummary(
        totalCards:             summary.value.totalCards > 0 ? summary.value.totalCards - 1 : 0,
        cardsAtTarget:          removed.isTargetReached && summary.value.cardsAtTarget > 0
            ? summary.value.cardsAtTarget - 1 : summary.value.cardsAtTarget,
        profitableCards:        removed.isProfitable && summary.value.profitableCards > 0
            ? summary.value.profitableCards - 1 : summary.value.profitableCards,
        totalInvested:          newInvested,
        totalCurrentValue:      newValue,
        totalProfitLoss:        newPL,
        totalProfitLossPercent: newPLPercent,
      );
    } else {
      cards[idx] = updated;
      cards.refresh();
    }

    // Quietly reconcile with the backend afterwards (exact fee math etc.)
    // without a loading spinner or blocking the UI the user already sees.
    _silentSync();
  }

  Future<void> _silentSync() async {
    try {
      final result = await _api.getCards();
      cards.assignAll(result.cards);
      summary.value = result.summary;
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    loadCards();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.keyUser);
      if (userJson != null) {
        user.value = UserModel.fromJson(jsonDecode(userJson));
      }
      // Also refresh from backend to get latest
      final fresh = await _api.getProfile();
      user.value = fresh;
      await prefs.setString(AppConstants.keyUser, jsonEncode(fresh.toJson()));
    } catch (_) {}
  }

  Future<void> loadCards() async {
    isLoading.value = true;
    try {
      final result = await _api.getCards();
      cards.assignAll(result.cards);
      summary.value = result.summary;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPrices() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    await loadCards();
    isRefreshing.value = false;
    Get.snackbar('✅ Prices Updated', 'Latest eBay prices loaded.',
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rt = prefs.getString(AppConstants.keyRefreshToken) ?? '';
      await _api.logout(rt);
      await prefs.clear();
    } catch (_) {}
    Get.offAllNamed(AppRoutes.login);
  }
}