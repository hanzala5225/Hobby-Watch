import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../routes/app_routes.dart';

class AddCardController extends GetxController {
  final _api = Get.find<ApiService>();
  final formKey         = GlobalKey<FormState>();
  final currentStep     = 0.obs;
  final isLoading       = false.obs;

  // Step 1 — Card details
  final playerNameController  = TextEditingController();
  final yearController        = TextEditingController();
  final setNameController     = TextEditingController();
  final brandController       = TextEditingController();
  final cardNumberController  = TextEditingController();
  final gradeController       = TextEditingController();
  final ebaySearchController  = TextEditingController();

  // Step 2 — Pricing
  final purchasePriceController  = TextEditingController();
  final targetMarginController   = TextEditingController(text: '30');

  String? _ebayAvgPrice;
  bool _fromScan = false;

  // Tracks whether the user has manually typed their own eBay search query.
  // Once true, we stop overwriting it as they keep editing the fields above —
  // their custom query wins.
  bool _userEditedSearchQuery = false;
  // Guards against our own programmatic updates to ebaySearchController
  // being mistaken for a user edit.
  bool _autoFilling = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _fromScan = args['fromScan'] ?? false;
      playerNameController.text = args['playerName'] ?? '';
      yearController.text       = args['year'] ?? '';
      setNameController.text    = args['setName'] ?? '';
      ebaySearchController.text = args['searchQuery'] ?? '';
      _ebayAvgPrice             = args['ebayAvgPrice']?.toString();

      // If a scan already supplied a search query, treat it as user-provided —
      // don't let the auto-fill below silently replace it.
      if (ebaySearchController.text.trim().isNotEmpty) {
        _userEditedSearchQuery = true;
      }
    }

    // Live auto-fill: whenever any of the card-identity fields change,
    // rebuild the eBay Search Query field (unless the user has typed their
    // own value into it).
    playerNameController.addListener(_composeAndFillQuery);
    yearController.addListener(_composeAndFillQuery);
    brandController.addListener(_composeAndFillQuery);
    setNameController.addListener(_composeAndFillQuery);
    cardNumberController.addListener(_composeAndFillQuery);
    gradeController.addListener(_composeAndFillQuery);
    ebaySearchController.addListener(_onSearchQueryEdited);

    // In case fields were pre-filled from a scan (playerName/year/setName
    // above), populate the query once right away.
    _composeAndFillQuery();
  }

  void _onSearchQueryEdited() {
    if (_autoFilling) return; // this change came from us, not the user
    _userEditedSearchQuery = true;
  }

  // Builds "{Player Name} {Year} {Brand} {Set} #{Card Number} {Grade}",
  // skipping any part that's empty, and fills it into the search field —
  // unless the user has already typed their own custom query.
  void _composeAndFillQuery() {
    if (_userEditedSearchQuery) return;

    final cardNumberRaw = cardNumberController.text.trim();
    final cardNumberPart = cardNumberRaw.isEmpty
        ? ''
        : (cardNumberRaw.startsWith('#') ? cardNumberRaw : '#$cardNumberRaw');

    final parts = <String>[
      playerNameController.text.trim(),
      yearController.text.trim(),
      brandController.text.trim(),
      setNameController.text.trim(),
      cardNumberPart,
      gradeController.text.trim(),
    ].where((p) => p.isNotEmpty).toList();

    final composed = parts.join(' ');

    _autoFilling = true;
    ebaySearchController.text = composed;
    _autoFilling = false;
  }

  void nextStep() {
    if (currentStep.value == 0) {
      // Validate step 1
      if (playerNameController.text.trim().isEmpty) {
        Get.snackbar('Required', 'Player name is required.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
        return;
      }
      if (yearController.text.trim().isEmpty) {
        Get.snackbar('Required', 'Year is required.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
        return;
      }
    }
    currentStep.value++;
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<void> saveCard() async {
    final priceText = purchasePriceController.text.trim();
    if (priceText.isEmpty || double.tryParse(priceText) == null) {
      Get.snackbar('Required', 'Enter a valid purchase price.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }

    isLoading.value = true;
    try {
      // Field is now auto-filled live as the user types (see
      // _composeAndFillQuery), so this is just a final safety net in case
      // it's still empty for some reason (e.g. every field was cleared).
      final searchQuery = ebaySearchController.text.trim().isNotEmpty
          ? ebaySearchController.text.trim()
          : '${playerNameController.text.trim()} ${yearController.text.trim()} ${brandController.text.trim()} ${setNameController.text.trim()} ${cardNumberController.text.trim()} ${gradeController.text.trim()}'.trim();

      await _api.addCard({
        'playerName':          playerNameController.text.trim(),
        'year':                yearController.text.trim(),
        'setName':             setNameController.text.trim().isNotEmpty ? setNameController.text.trim() : null,
        'brand':               brandController.text.trim().isNotEmpty ? brandController.text.trim() : null,
        'cardNumber':          cardNumberController.text.trim().isNotEmpty ? cardNumberController.text.trim() : null,
        'grade':               gradeController.text.trim().isNotEmpty ? gradeController.text.trim() : null,
        'purchasePrice':       double.parse(priceText),
        'targetMarginPercent': double.tryParse(targetMarginController.text) ?? 30.0,
        'ebaySearchQuery':     searchQuery,
        'addedVia':            _fromScan ? 'scan' : 'manual',
        'sport':               'Basketball',
      });

      Get.snackbar('✅ Card Added', 'eBay prices will update shortly.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add card. Please try again.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    playerNameController.removeListener(_composeAndFillQuery);
    yearController.removeListener(_composeAndFillQuery);
    brandController.removeListener(_composeAndFillQuery);
    setNameController.removeListener(_composeAndFillQuery);
    cardNumberController.removeListener(_composeAndFillQuery);
    gradeController.removeListener(_composeAndFillQuery);
    ebaySearchController.removeListener(_onSearchQueryEdited);

    playerNameController.dispose();
    yearController.dispose();
    setNameController.dispose();
    brandController.dispose();
    cardNumberController.dispose();
    gradeController.dispose();
    ebaySearchController.dispose();
    purchasePriceController.dispose();
    targetMarginController.dispose();
    super.onClose();
  }
}