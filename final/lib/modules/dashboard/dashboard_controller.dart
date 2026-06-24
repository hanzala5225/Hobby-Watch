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
    if (idx != -1) {
      cards[idx] = updated;
      cards.refresh();
    }
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