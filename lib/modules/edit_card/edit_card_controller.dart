import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';
import '../collection/collection_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../sold_history/sold_history_controller.dart';

class EditCardController extends GetxController {
  final _api = Get.find<ApiService>();
  late final CardModel originalCard = Get.arguments as CardModel;
  final isSaving = false.obs;

  late final playerNameController    = TextEditingController(text: originalCard.playerName);
  late final yearController          = TextEditingController(text: originalCard.year);
  late final setNameController       = TextEditingController(text: originalCard.setName ?? '');
  late final parallelController      = TextEditingController(text: originalCard.parallel ?? '');
  late final brandController         = TextEditingController(text: originalCard.brand ?? '');
  late final cardNumberController    = TextEditingController(text: originalCard.cardNumber ?? '');
  late final gradeController         = TextEditingController(text: originalCard.grade ?? '');
  late final purchasePriceController = TextEditingController(text: originalCard.purchasePrice.toStringAsFixed(2));
  late final targetMarginController  = TextEditingController(text: originalCard.targetMarginPercent.toStringAsFixed(0));

  Future<void> saveChanges() async {
    final playerName = playerNameController.text.trim();
    if (playerName.isEmpty) {
      Get.snackbar('Required', 'Player name is required.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
    final year = yearController.text.trim();
    if (year.isEmpty) {
      Get.snackbar('Required', 'Year is required.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
    final price = double.tryParse(purchasePriceController.text.trim());
    if (price == null || price <= 0) {
      Get.snackbar('Required', 'Enter a valid purchase price.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }

    isSaving.value = true;
    try {
      final updated = await _api.updateCard(originalCard.id, {
        'playerName':          playerName,
        'year':                year,
        'setName':             setNameController.text.trim().isNotEmpty ? setNameController.text.trim() : null,
        'parallel':            parallelController.text.trim().isNotEmpty ? parallelController.text.trim() : null,
        'brand':               brandController.text.trim().isNotEmpty ? brandController.text.trim() : null,
        'cardNumber':          cardNumberController.text.trim().isNotEmpty ? cardNumberController.text.trim() : null,
        'grade':               gradeController.text.trim().isNotEmpty ? gradeController.text.trim() : null,
        'purchasePrice':       price,
        'targetMarginPercent': double.tryParse(targetMarginController.text.trim()) ?? originalCard.targetMarginPercent,
      });

      // Keep other screens' local card lists in sync immediately — same
      // pattern already used after marking a card sold.
      try {
        final collectionCtrl = Get.find<CollectionController>();
        final idx = collectionCtrl.cards.indexWhere((c) => c.id == updated.id);
        if (idx != -1) {
          collectionCtrl.cards[idx] = updated;
          collectionCtrl.cards.refresh();
        }
      } catch (_) {}
      try {
        Get.find<DashboardController>().updateCardInPlace(updated);
      } catch (_) {}
      try {
        Get.find<SoldHistoryController>().loadSoldCards();
      } catch (_) {}

      Get.back(result: updated);
      Get.snackbar('✅ Saved', 'Card details updated.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', 'Could not save changes. Please try again.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    playerNameController.dispose();
    yearController.dispose();
    setNameController.dispose();
    parallelController.dispose();
    brandController.dispose();
    cardNumberController.dispose();
    gradeController.dispose();
    purchasePriceController.dispose();
    targetMarginController.dispose();
    super.onClose();
  }
}