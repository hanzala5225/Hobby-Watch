import 'dart:async';
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
  final isLoadingMore = false.obs;
  final searchQuery   = ''.obs;
  final sortBy        = 'created_at'.obs;
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Bug fix (2026-08): the collection screen used to load a single page of
  // 50 cards and never fetch more, and search filtered only that already-
  // loaded list client-side — so any card past the first 50 added was
  // invisible to both browsing and search, even though the backend already
  // supported real pagination and full-collection search. Now both go
  // through the API properly: infinite scroll for browsing, and the search
  // term is sent to the backend so it matches across the user's ENTIRE
  // collection, not just what's currently loaded on screen.
  static const int _pageSize = 50;
  static const int _targetReachedPageSize = 500; // matches app's max_cards_per_user cap — this view is a bounded, occasional-use list, so it loads in one page rather than needing scroll pagination

  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  Timer? _searchDebounce;

  // 'all' or 'targetReached' — set from Get.arguments when navigated here
  // via the dashboard's "Ready to Sell" → View all link.
  final filterMode = 'all'.obs;

  // Search and pagination happen server-side now (see loadCards/_loadMoreCards).
  // This getter only applies the sold/target-reached split locally, since
  // those are cheap to filter on the already-correct, already-complete set
  // the current mode has loaded.
  List<CardModel> get filteredCards {
    var active = cards.where((c) => !c.isSold).toList();
    if (filterMode.value == 'targetReached') {
      active = active.where((c) => c.isTargetReached).toList();
    }
    return active;
  }

  List<CardModel> get soldCards => cards.where((c) => c.isSold).toList();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['filter'] == 'targetReached') {
      filterMode.value = 'targetReached';
    }
    scrollController.addListener(_onScroll);
    loadCards();
  }

  void onResume() {
    loadCards();
  }

  void _onScroll() {
    if (filterMode.value == 'targetReached') return; // loaded in full already
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      _loadMoreCards();
    }
  }

  /// Switches filter mode (All / Ready to Sell) and reloads from page 1 —
  /// the two modes use different page sizes (see class docs above), so a
  /// reload is required rather than just re-filtering the existing list.
  void setFilterMode(String mode) {
    if (filterMode.value == mode) return;
    filterMode.value = mode;
    loadCards();
  }

  /// Resets to page 1 and reloads. Used for pull-to-refresh, initial load,
  /// a filter-mode switch, and (via the debounced search handler) whenever
  /// the search text settles.
  Future<void> loadCards() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMore = true;
    try {
      final pageSize = filterMode.value == 'targetReached'
          ? _targetReachedPageSize
          : _pageSize;
      final result = await _api.getCards(
        page: 1,
        pageSize: pageSize,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        sortBy: sortBy.value,
      );
      cards.assignAll(result.cards);
      summary.value = result.summary;
      _totalCount = result.totalCount;
      _hasMore = cards.length < _totalCount;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMoreCards() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final result = await _api.getCards(
        page: nextPage,
        pageSize: _pageSize,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        sortBy: sortBy.value,
      );
      cards.addAll(result.cards);
      _currentPage = nextPage;
      _totalCount = result.totalCount;
      _hasMore = cards.length < _totalCount;
    } catch (_) {} finally {
      isLoadingMore.value = false;
    }
  }

  void onSearchChanged(String q) {
    searchQuery.value = q;
    // Debounce so we're not hitting the backend on every keystroke — reload
    // from page 1 with the new search term once typing pauses briefly.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), loadCards);
  }

  Future<void> deleteCard(String id) async {
    await _api.deleteCard(id);
    cards.removeWhere((c) => c.id == id);
    if (_totalCount > 0) _totalCount -= 1;
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
    _searchDebounce?.cancel();
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }
}