import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/card_model.dart';
import '../../data/services/api_service.dart';
import '../collection/collection_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../sold_history/sold_history_controller.dart';

class CardDetailController extends GetxController {
  final _api = Get.find<ApiService>();
  late final card = Rx<CardModel>(Get.arguments as CardModel);
  final isRefreshing  = false.obs;
  final isMarkingSold = false.obs;
  final priceHistory  = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> refreshPrice() async {
    isRefreshing.value = true;
    try {
      final updated = await _api.refreshCardPrice(card.value.id);
      card.value = updated;
      await loadHistory();
      Get.snackbar('✅ Price Updated', 'Latest eBay data loaded.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', 'Could not refresh price.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      final h = await _api.getPriceHistory(card.value.id);
      priceHistory.assignAll(h);
    } catch (_) {}
  }

  Future<void> deleteCard() async {
    try {
      await _api.deleteCard(card.value.id);
      Get.back();
      Get.snackbar('Card Removed', '${card.value.playerName} removed from collection.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (_) {}
  }

  Future<void> showMarkSoldDialog(BuildContext context) async {
    final soldPriceController = TextEditingController(
      text: card.value.currentEbayAvg30?.toStringAsFixed(2) ?? '',
    );
    final shippingChargeController = TextEditingController();
    final soldOutsideEbay = false.obs;
    final shippingNotNeeded = false.obs;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => MarkSoldDialog(
        card: card.value,
        soldPriceController: soldPriceController,
        shippingChargeController: shippingChargeController,
        soldOutsideEbay: soldOutsideEbay,
        shippingNotNeeded: shippingNotNeeded,
      ),
    );

    if (confirmed == true) {
      final price = double.tryParse(soldPriceController.text.replaceAll(',', '.'));
      if (price == null || price <= 0) {
        Get.snackbar('Invalid Price', 'Please enter a valid sold price.',
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
        _disposeAfterDialogCloses(soldPriceController);
        shippingChargeController.dispose();
        return;
      }
      // Shipping is irrelevant once sold-outside-eBay or shipping-not-needed
      // is checked — treat it as 0 regardless of leftover text in the field.
      final shipping = (soldOutsideEbay.value || shippingNotNeeded.value)
          ? 0.0
          : (double.tryParse(shippingChargeController.text.replaceAll(',', '.')) ?? 0.0);
      await _doMarkSold(price, soldOutsideEbay.value, shipping);
    }
    _disposeAfterDialogCloses(soldPriceController);
    shippingChargeController.dispose();
  }

  void _disposeAfterDialogCloses(TextEditingController controller) {
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
  }

  Future<void> _doMarkSold(double soldPrice, bool soldOutsideEbay, double shippingCharge) async {
    isMarkingSold.value = true;
    try {
      final updated = await _api.markAsSold(card.value.id, soldPrice,
          soldOutsideEbay: soldOutsideEbay, shippingCharge: shippingCharge);
      card.value = updated;

      // ── Immediately update CollectionController and DashboardController ──
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

      // Also update sold history if it's open
      try {
        Get.find<SoldHistoryController>().loadSoldCards();
      } catch (_) {}

      Get.back();
      Get.snackbar(
        '🎉 Sold!',
        '${card.value.playerName} moved to sold history.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not mark card as sold.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isMarkingSold.value = false;
    }
  }
}

class MarkSoldDialog extends StatelessWidget {
  final CardModel card;
  final TextEditingController soldPriceController;
  final TextEditingController shippingChargeController;
  final RxBool soldOutsideEbay;
  final RxBool shippingNotNeeded;
  const MarkSoldDialog({
    super.key,
    required this.card,
    required this.soldPriceController,
    required this.shippingChargeController,
    required this.soldOutsideEbay,
    required this.shippingNotNeeded,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isTarget = card.isTargetReached;

    // Material's Dialog widget already shifts itself above the keyboard
    // internally (it pads by MediaQuery.viewInsets.bottom). We used to ALSO
    // wrap it in our own keyboard-offset Padding on top of that — a double
    // shift that pushed the dialog above the visible screen, which then
    // forced Flutter's "scroll the focused field into view" behavior to
    // snap the scroll position down, hiding the header and buttons. Fixed
    // by removing that outer Padding and instead sizing maxHeight against
    // the space actually visible above the keyboard, so the full popup
    // fits and can be scrolled as one piece.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final visibleHeight = screenHeight - keyboardHeight;
    final maxDialogHeight = (visibleHeight - 48.h).clamp(280.h, screenHeight * 0.85);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          // Header and body now live inside ONE scroll view. Previously the
          // header sat outside the scrollable area with no way to shrink,
          // so when the keyboard squeezed the available height it
          // overflowed. Now, if content ever doesn't fit, the whole dialog
          // scrolls instead of overflowing.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
                    decoration: BoxDecoration(
                      gradient: isTarget ? AppColors.profitGradient : AppColors.heroGradient,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(Icons.sell_rounded, color: Colors.white, size: 18.sp),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            isTarget ? '🎯 Target Reached!' : 'Mark as Sold',
                            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ]),
                        SizedBox(height: 12.h),
                        Text(card.playerName,
                            style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${card.year}  •  ${card.setName ?? ""}',
                            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70)),
                        if (isTarget) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '+${card.currentMarginPercent?.toStringAsFixed(1)}% margin — above your ${card.targetMarginPercent.toStringAsFixed(0)}% target 🚀',
                              style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Body ──────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price summary
                        Row(children: [
                          Expanded(child: _box('Paid', fmt.format(card.purchasePrice), AppColors.textSecondary)),
                          SizedBox(width: 8.w),
                          Expanded(child: _box('Market Est.',
                              card.currentEbayAvg30 != null ? fmt.format(card.currentEbayAvg30!) : '—',
                              AppColors.accent)),
                        ]),
                        SizedBox(height: 18.h),

                        // Sold price input
                        Text('What did it sell for?',
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: soldPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            prefixText: '\$  ',
                            prefixStyle: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            hintText: '0.00',
                            hintStyle: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w800, color: AppColors.border),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // "Sold outside of eBay" checkbox
                        Obx(() => GestureDetector(
                          onTap: () => soldOutsideEbay.value = !soldOutsideEbay.value,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: soldOutsideEbay.value ? AppColors.accent.withOpacity(0.08) : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: soldOutsideEbay.value ? AppColors.accent.withOpacity(0.3) : AppColors.border),
                            ),
                            child: Row(children: [
                              Icon(
                                soldOutsideEbay.value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: soldOutsideEbay.value ? AppColors.accent : AppColors.textMuted,
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(child: Text(
                                'Sold outside of eBay — No Fees',
                                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              )),
                            ]),
                          ),
                        )),

                        // Shipping section
                        Obx(() {
                          if (soldOutsideEbay.value) return const SizedBox();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16.h),
                              Text('Shipping charged to buyer',
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              SizedBox(height: 4.h),
                              Text('eBay applies its fee to the sold price + shipping combined.',
                                  style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                              SizedBox(height: 8.h),
                              Obx(() => TextFormField(
                                controller: shippingChargeController,
                                enabled: !shippingNotNeeded.value,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700,
                                    color: shippingNotNeeded.value ? AppColors.textMuted : AppColors.textPrimary),
                                decoration: InputDecoration(
                                  prefixText: '\$  ',
                                  prefixStyle: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                  hintText: '0.00',
                                  filled: shippingNotNeeded.value,
                                  fillColor: AppColors.bgSurface,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                ),
                              )),
                              SizedBox(height: 10.h),

                              Obx(() => GestureDetector(
                                onTap: () {
                                  shippingNotNeeded.value = !shippingNotNeeded.value;
                                  if (shippingNotNeeded.value) shippingChargeController.clear();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: shippingNotNeeded.value ? AppColors.accent.withOpacity(0.08) : AppColors.bgSurface,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: shippingNotNeeded.value ? AppColors.accent.withOpacity(0.3) : AppColors.border),
                                  ),
                                  child: Row(children: [
                                    Icon(
                                      shippingNotNeeded.value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      color: shippingNotNeeded.value ? AppColors.accent : AppColors.textMuted,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(child: Text(
                                      'Shipping not needed (e.g. local pickup)',
                                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    )),
                                  ]),
                                ),
                              )),
                            ],
                          );
                        }),

                        SizedBox(height: 14.h),

                        // Live fee preview
                        AnimatedBuilder(
                          animation: Listenable.merge([soldPriceController, shippingChargeController]),
                          builder: (_, __) => Obx(() {
                            final soldPrice = double.tryParse(soldPriceController.text.replaceAll(',', '.')) ?? 0;
                            final shipping = (soldOutsideEbay.value || shippingNotNeeded.value)
                                ? 0.0
                                : (double.tryParse(shippingChargeController.text.replaceAll(',', '.')) ?? 0.0);
                            final combined = soldPrice + shipping;
                            final feeAmount = soldOutsideEbay.value ? 0.0 : combined * (card.ebayFeePercent / 100);
                            final afterFees = combined - feeAmount;

                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(soldOutsideEbay.value ? 'eBay fee' : 'eBay fee (${card.ebayFeePercent.toStringAsFixed(2)}%)',
                                      style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                                  Text(soldOutsideEbay.value ? 'None' : '-${fmt.format(feeAmount)}',
                                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.loss)),
                                ]),
                                SizedBox(height: 4.h),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('You keep', style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                                  Text(fmt.format(afterFees),
                                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ]),
                              ]),
                            );
                          }),
                        ),

                        SizedBox(height: 22.h),

                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: Size(0, 50.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text('Cancel',
                                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, true),
                              child: Container(
                                height: 50.h,
                                decoration: BoxDecoration(
                                  gradient: isTarget ? AppColors.profitGradient : AppColors.heroGradient,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [BoxShadow(
                                    color: (isTarget ? AppColors.accent : AppColors.primary).withOpacity(0.3),
                                    blurRadius: 14, offset: const Offset(0, 4),
                                  )],
                                ),
                                child: Center(
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    Text('Confirm Sale',
                                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
      );
  }

  Widget _box(String label, String value, Color valueColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(10.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
        SizedBox(height: 4.h),
        Text(value, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: valueColor)),
      ]),
    );
  }
}