import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/ebay_result_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/ocr_service.dart';
import '../routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';

enum ScanStep { choose, processing, verify, results, confirm }

class ScanCardController extends GetxController with WidgetsBindingObserver {
  final _ocr  = Get.find<OcrService>();
  final _api  = Get.find<ApiService>();
  final _picker = ImagePicker();

  // Set right before we send the user to iOS/Android Settings, so that when
  // they come back we know to re-check the camera permission automatically
  // instead of waiting for them to tap "Scan with Camera" again.
  bool _awaitingSettingsReturn = false;

  // "Add Card" (the old Verify Details screen) is now the true entry point —
  // tapping Add Card lands here directly, with the camera/gallery scanner
  // reachable only via the "Try our Graded Card Scanner (beta)" button.
  final currentStep       = ScanStep.verify.obs;
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
    WidgetsBinding.instance.addObserver(this);
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

  // Called automatically when the app comes back to the foreground — e.g.
  // Tim backgrounds the app, flips Camera ON in Settings, then returns.
  // iOS/Android don't always refresh a running app's cached permission
  // state on simple resume, so we explicitly re-check here rather than
  // waiting for another tap on "Scan with Camera".
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingSettingsReturn) {
      _awaitingSettingsReturn = false;
      _recheckCameraPermission();
    }
  }

  Future<void> _recheckCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      errorMessage.value = '';
    }
    // If it's still denied here, the OS-level toggle genuinely isn't on,
    // or (on iOS especially) the change needs a full app restart to take
    // effect — the error banner's copy covers that case.
  }

  Future<void> takePhoto() async {
    // iOS silently refuses to launch the camera if permission was ever
    // denied — image_picker alone doesn't handle re-prompting or recovery.
    // Check current status first (non-prompting) rather than always calling
    // request(), since request() on an already-decided permission can hand
    // back a stale cached result on some OS/plugin versions.
    var status = await Permission.camera.status;
    if (status.isDenied) {
      // Only truly undetermined permissions get the system dialog.
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      _awaitingSettingsReturn = true;
      errorMessage.value = 'Camera access is turned off. Enable it in Settings to scan cards. '
          'If you just enabled it, please fully close and reopen Hobby Watch, then try again.';
      Get.snackbar('Camera Permission Needed', 'Enable camera access in Settings to scan cards.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12,
          mainButton: TextButton(onPressed: () {
            _awaitingSettingsReturn = true;
            openAppSettings();
          }, child: const Text('Open Settings', style: TextStyle(color: Colors.white))));
      return;
    }
    if (!status.isGranted) {
      errorMessage.value = 'Camera permission is required to scan cards.';
      return;
    }

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

  // Opens the camera/gallery scanner from the "Add Card" screen's new
  // "Try our Graded Card Scanner (beta)" button. Whatever the user has
  // already typed manually is left untouched unless a scan actually completes.
  void openGradedScanner() {
    currentStep.value = ScanStep.choose;
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
    if (q.isEmpty) {
      Get.snackbar('Nothing to Search', 'Enter at least the player name before searching eBay.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
      return;
    }
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
    Get.toNamed(AppRoutes.addCard, arguments: {
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
      'searchQueryUserEdited': _userEditedQuery,
      'imageUrl':    selectedResult.value?.imageUrl,
    });
  }

  void goManualAdd() {
    Get.toNamed(AppRoutes.addCard, arguments: {
      'fromScan':    false,
      'playerName':  playerNameController.text,
      'year':        yearController.text,
      'setName':     setNameController.text,
      'parallel':    parallelController.text,
      'cardNumber':  cardNumberController.text,
      'grade':       gradeController.text,
      'searchQuery': searchQueryController.text,
      'searchQueryUserEdited': _userEditedQuery,
    });
  }

  void goBack() {
    switch (currentStep.value) {
      case ScanStep.choose:
      // Came here from "Add Card" via the Graded Card Scanner button.
        currentStep.value = ScanStep.verify;
        break;
      case ScanStep.results:
        currentStep.value = ScanStep.verify;
        break;
      case ScanStep.confirm:
        currentStep.value = ScanStep.results;
        break;
      default:
      // ScanStep.verify ("Add Card") is now the entry point — back exits
      // the whole flow, same as ScanStep.processing falling through here.
        Get.back();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
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