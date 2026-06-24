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
    }
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
      final searchQuery = ebaySearchController.text.trim().isNotEmpty
          ? ebaySearchController.text.trim()
          : '${yearController.text} ${brandController.text} ${setNameController.text} ${playerNameController.text} ${gradeController.text}'.trim();

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
