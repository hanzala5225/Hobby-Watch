import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/ebay_result_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/ocr_service.dart';
import '../routes/app_routes.dart';

enum ScanStep { choose, processing, results, confirm, manual }

class ScanCardController extends GetxController {
  final _ocr  = Get.find<OcrService>();
  final _api  = Get.find<ApiService>();
  final _picker = ImagePicker();

  final currentStep       = ScanStep.choose.obs;
  final isProcessing      = false.obs;
  final errorMessage      = ''.obs;
  final scannedImageFile  = Rx<File?>(null);
  final ebayResults       = <EbayListingItem>[].obs;
  final searchResponse    = Rx<EbaySearchResponse?>(null);
  final selectedResult    = Rx<EbayListingItem?>(null);
  final scanResult        = Rx<ScanResult?>(null);

  // Editable fields
  final searchQueryController = TextEditingController();
  final playerNameController  = TextEditingController();
  final yearController        = TextEditingController();
  final setNameController     = TextEditingController();

  // Manual entry fallback
  final isManualMode = false.obs;

  Future<void> takePhoto() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92, maxWidth: 1800);
      if (img == null) return;
      scannedImageFile.value = File(img.path);
      await _processImage(File(img.path));
    } catch (e) {
      errorMessage.value = 'Could not open camera. Please try again.';
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (img == null) return;
      scannedImageFile.value = File(img.path);
      await _processImage(File(img.path));
    } catch (e) {
      errorMessage.value = 'Could not open gallery. Please try again.';
    }
  }

  void enterManually() {
    isManualMode.value = true;
    // Clear any previous scan data
    playerNameController.clear();
    yearController.clear();
    setNameController.clear();
    currentStep.value = ScanStep.manual;
  }

  Future<void> _processImage(File f) async {
    currentStep.value = ScanStep.processing;
    isProcessing.value = true;
    errorMessage.value = '';
    try {
      final result = await _ocr.scanCard(f);
      scanResult.value = result;
      searchQueryController.text = result.searchQuery;
      playerNameController.text  = result.playerName ?? '';
      yearController.text        = result.year ?? '';
      setNameController.text     = result.setName ?? result.brand ?? '';
      await _searchEbay(result.searchQuery);
    } catch (e) {
      errorMessage.value = 'Could not process image. Edit the query below manually.';
      currentStep.value = ScanStep.results;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _searchEbay(String query) async {
    try {
      final res = await _api.searchEbay(query);
      searchResponse.value = res;
      ebayResults.assignAll(res.listings);
      currentStep.value = ScanStep.results;
    } catch (e) {
      errorMessage.value = 'eBay search failed. Try editing the query.';
      ebayResults.clear();
      currentStep.value = ScanStep.results;
    }
  }

  Future<void> retrySearch() async {
    final q = searchQueryController.text.trim();
    if (q.isEmpty) return;
    isProcessing.value = true;
    currentStep.value = ScanStep.processing;
    await _searchEbay(q);
    isProcessing.value = false;
  }

  void selectResult(EbayListingItem result) {
    selectedResult.value = result;
    currentStep.value = ScanStep.confirm;
  }

  void confirmAndAddCard() {
    Get.offNamed(AppRoutes.addCard, arguments: {
      'fromScan':    true,
      'playerName':  playerNameController.text,
      'year':        yearController.text,
      'setName':     setNameController.text,
      'cardName':    selectedResult.value?.title ?? '',
      'ebayAvgPrice':searchResponse.value?.avg30Day ?? selectedResult.value?.price ?? 0.0,
      'searchQuery': searchQueryController.text,
    });
  }

  void goManualAdd() {
    Get.offNamed(AppRoutes.addCard, arguments: {
      'fromScan':    false,
      'playerName':  playerNameController.text,
      'year':        yearController.text,
      'setName':     setNameController.text,
      'searchQuery': searchQueryController.text,
    });
  }

  void goBack() {
    switch (currentStep.value) {
      case ScanStep.manual:
        currentStep.value = ScanStep.choose;
        isManualMode.value = false;
        break;
      case ScanStep.results:
        currentStep.value = ScanStep.choose;
        isManualMode.value = false;
        break;
      case ScanStep.confirm:
        currentStep.value = isManualMode.value ? ScanStep.manual : ScanStep.results;
        break;
      default:
        Get.back();
    }
  }

  @override
  void onClose() {
    searchQueryController.dispose();
    playerNameController.dispose();
    yearController.dispose();
    setNameController.dispose();
    super.onClose();
  }
}