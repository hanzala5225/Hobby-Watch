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
  final unreadCount  = 0.obs;

  // Capped at 6 + sorted by highest margin first (most urgent to sell) — the
  // header badge next to this section uses summary.cardsAtTarget for the
  // TRUE total count, since this list is deliberately capped for the
  // horizontal preview strip. "View all" links to the Collection screen's
  // Ready-to-Sell filter to see the rest.
  List<CardModel> get targetReachedCards {
    final list = cards.where((c) => c.isTargetReached && !c.isSold).toList()
      ..sort((a, b) => (b.currentMarginPercent ?? 0).compareTo(a.currentMarginPercent ?? 0));
    return list.take(6).toList();
  }
  List<CardModel> get recentCards        => cards.where((c) => !c.isSold).take(5).toList();

  // Cards added in the last 7 days — used for the "this week" indicator.
  // Computed from data already on each card (createdAt), no new backend
  // tracking needed.
  int get cardsAddedThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return cards.where((c) => c.createdAt.isAfter(weekAgo)).length;
  }

  double get investedThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return cards.where((c) => c.createdAt.isAfter(weekAgo))
        .fold(0.0, (sum, c) => sum + c.purchasePrice);
  }

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
    refreshUnreadCount();
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

  // Public so other controllers (add-card, notifications screen) can trigger
  // a refresh after doing something that changes the unread count — e.g.
  // Get.find<DashboardController>().refreshUnreadCount() after marking a
  // notification read, or after adding a card that fires an alert.
  Future<void> refreshUnreadCount() async {
    unreadCount.value = await _api.getUnreadNotificationCount();
  }

  Future<void> refreshPrices() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    await loadCards();
    await refreshUnreadCount();
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