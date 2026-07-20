import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/ebay_result_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/ocr_service.dart';
import '../routes/app_routes.dart';

enum ScanStep { choose, processing, verify, results, confirm, manual }

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
  final parallelController    = TextEditingController();
  final cardNumberController  = TextEditingController();
  final gradeController       = TextEditingController();

  // Manual entry fallback
  final isManualMode = false.obs;

  // Tracks whether the user has manually typed their own eBay search query on
  // the Verify screen. Once true, we stop overwriting it as the fields above
  // change — their custom query wins.
  bool _userEditedQuery = false;
  // Guards against our own programmatic updates to searchQueryController
  // being mistaken for a user edit.
  bool _autoFilling = false;

  @override
  void onInit() {
    super.onInit();
    playerNameController.addListener(_composeQuery);
    yearController.addListener(_composeQuery);
    setNameController.addListener(_composeQuery);
    parallelController.addListener(_composeQuery);
    cardNumberController.addListener(_composeQuery);
    gradeController.addListener(_composeQuery);
    searchQueryController.addListener(_onQueryEdited);
  }

  void _onQueryEdited() {
    if (_autoFilling) return;
    _userEditedQuery = true;
  }

  // Builds "{Player Name} {Year} {Brand/Set} {Parallel} #{Card Number} {Grade}",
  // skipping any part that's empty, and fills it into the search query field —
  // unless the user has already typed their own custom query on the Verify
  // screen. This is what lets the user catch anything OCR missed or got
  // wrong (e.g. the parallel/variety, which OCR doesn't detect at all) before
  // it's ever sent to the eBay API.
  void _composeQuery() {
    if (_userEditedQuery) return;

    final cardNumRaw = cardNumberController.text.trim();
    final cardNumPart = cardNumRaw.isEmpty
        ? ''
        : (cardNumRaw.startsWith('#') ? cardNumRaw : '#$cardNumRaw');

    final parts = <String>[
      playerNameController.text.trim(),
      yearController.text.trim(),
      setNameController.text.trim(),
      parallelController.text.trim(),
      cardNumPart,
      gradeController.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    _autoFilling = true;
    searchQueryController.text = parts.join(' ');
    _autoFilling = false;
  }

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
    parallelController.clear();
    cardNumberController.clear();
    gradeController.clear();
    searchQueryController.clear();
    _userEditedQuery = false;
    currentStep.value = ScanStep.manual;
  }

  Future<void> _processImage(File f) async {
    currentStep.value = ScanStep.processing;
    isProcessing.value = true;
    errorMessage.value = '';
    _userEditedQuery = false;
    try {
      final result = await _ocr.scanCard(f);
      scanResult.value = result;
      playerNameController.text  = result.playerName ?? '';
      yearController.text        = result.year ?? '';
      setNameController.text     = result.setName ?? result.brand ?? '';
      cardNumberController.text  = result.cardNumber ?? '';
      gradeController.text       = result.grade ?? '';
      // parallelController is intentionally left blank — OCR doesn't detect
      // the parallel/variety yet, so the user fills it in on the Verify screen.
      _composeQuery();
      // Land on Verify instead of searching immediately, so the user can
      // correct anything OCR missed or got wrong before it's sent to eBay.
      currentStep.value = ScanStep.verify;
    } catch (e) {
      errorMessage.value = 'Could not process image. Fill in the details below manually.';
      currentStep.value = ScanStep.verify;
    } finally {
      isProcessing.value = false;
    }
  }

  // Called from the 3-field manual entry screen's "Search eBay" button —
  // routes through Verify too, so the user can add Parallel/Card #/Grade
  // (which that screen doesn't capture) before the search actually fires.
  void goToVerify() {
    if (playerNameController.text.trim().isEmpty) {
      Get.snackbar('Fill in details', 'Add at least a player name to search.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
    _composeQuery();
    currentStep.value = ScanStep.verify;
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

  // Called from the Verify screen's "Search eBay" button, and reused to
  // retry/edit a search from the Results screen's search bar.
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
      'parallel':    parallelController.text,
      'cardNumber':  cardNumberController.text,
      'grade':       gradeController.text,
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
      'parallel':    parallelController.text,
      'cardNumber':  cardNumberController.text,
      'grade':       gradeController.text,
      'searchQuery': searchQueryController.text,
    });
  }

  void goBack() {
    switch (currentStep.value) {
      case ScanStep.manual:
        currentStep.value = ScanStep.choose;
        isManualMode.value = false;
        break;
      case ScanStep.verify:
        currentStep.value = isManualMode.value ? ScanStep.manual : ScanStep.choose;
        break;
      case ScanStep.results:
        currentStep.value = ScanStep.verify;
        break;
      case ScanStep.confirm:
        currentStep.value = ScanStep.results;
        break;
      default:
        Get.back();
    }
  }

  @override
  void onClose() {
    playerNameController.removeListener(_composeQuery);
    yearController.removeListener(_composeQuery);
    setNameController.removeListener(_composeQuery);
    parallelController.removeListener(_composeQuery);
    cardNumberController.removeListener(_composeQuery);
    gradeController.removeListener(_composeQuery);
    searchQueryController.removeListener(_onQueryEdited);

    searchQueryController.dispose();
    playerNameController.dispose();
    yearController.dispose();
    setNameController.dispose();
    parallelController.dispose();
    cardNumberController.dispose();
    gradeController.dispose();
    super.onClose();
  }
}