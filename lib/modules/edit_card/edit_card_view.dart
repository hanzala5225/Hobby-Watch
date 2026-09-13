import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import 'edit_card_controller.dart';

class EditCardView extends GetView<EditCardController> {
  const EditCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Edit Card',
            style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: Get.back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Card Identity'),
                    SizedBox(height: 10.h),
                    _label('Player Name *'),
                    SizedBox(height: 8.h),
                    TextFormField(
                        controller: controller.playerNameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                            hintText: 'e.g. Michael Jordan',
                            prefixIcon: Icon(Icons.person_outline,
                                color: AppColors.textMuted, size: 20.sp))),
                    SizedBox(height: 18.h),
                    _label('Year *'),
                    SizedBox(height: 8.h),
                    TextFormField(
                        controller: controller.yearController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                            hintText: '1996',
                            prefixIcon: Icon(Icons.calendar_today_outlined,
                                color: AppColors.textMuted, size: 20.sp),
                            counterText: '')),
                    SizedBox(height: 18.h),
                    _label('Brand (optional)'),
                    SizedBox(height: 8.h),
                    TextFormField(
                        controller: controller.brandController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                            hintText: 'e.g. Topps, Panini',
                            prefixIcon: Icon(Icons.business_outlined,
                                color: AppColors.textMuted, size: 20.sp))),
                    SizedBox(height: 18.h),
                    _label('Set / Series (optional)'),
                    SizedBox(height: 8.h),
                    TextFormField(
                        controller: controller.setNameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                            hintText: 'e.g. Topps Chrome',
                            prefixIcon: Icon(Icons.layers_outlined,
                                color: AppColors.textMuted, size: 20.sp))),
                    SizedBox(height: 18.h),
                    _label('Parallel / Variety (optional)'),
                    SizedBox(height: 8.h),
                    TextFormField(
                        controller: controller.parallelController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                            hintText: 'e.g. Silver, Gold Refractor',
                            prefixIcon: Icon(Icons.auto_awesome_outlined,
                                color: AppColors.textMuted, size: 20.sp))),
                    SizedBox(height: 18.h),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _label('Card # (optional)'),
                            SizedBox(height: 8.h),
                            TextFormField(
                                controller: controller.cardNumberController,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.sp),
                                decoration:
                                    const InputDecoration(hintText: '#139')),
                          ])),
                      SizedBox(width: 12.w),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _label('Grade (optional)'),
                            SizedBox(height: 8.h),
                            TextFormField(
                                controller: controller.gradeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.sp),
                                decoration:
                                    const InputDecoration(hintText: 'PSA 10')),
                          ])),
                    ]),

                    SizedBox(height: 28.h),
                    _sectionLabel('Pricing'),
                    SizedBox(height: 10.h),
                    _label('Purchase Price *'),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: controller.purchasePriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14.sp),
                      decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money,
                              color: AppColors.textMuted, size: 20.sp)),
                    ),
                    SizedBox(height: 18.h),
                    _label('Target Profit Margin (%)'),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: controller.targetMarginController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14.sp),
                      decoration: InputDecoration(
                          hintText: '30',
                          prefixIcon: Icon(Icons.trending_up_rounded,
                              color: AppColors.textMuted, size: 20.sp),
                          suffixText: '%',
                          suffixStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14.sp)),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            color: AppColors.accent, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                            child: Text(
                                'This updates the card\'s saved details. It won\'t re-search eBay. Use the refresh button on the card page for that.',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary,
                                    height: 1.4))),
                      ]),
                    ),

                    // Sold-sale details — view only. Added per Tim's request
                    // (2026-08-26): once a card is marked sold, the shipping/tax
                    // entered at that time become part of its historical profit
                    // record. Showing them read-only (grayed out) rather than in
                    // an editable field, since letting them change after the
                    // fact would mean quietly rewriting real sale history — the
                    // profit/ROI numbers everywhere else in the app are computed
                    // from these exact values at time of sale.
                    if (controller.originalCard.isSold) ...[
                      SizedBox(height: 28.h),
                      _sectionLabel('Sale Details'),
                      SizedBox(height: 6.h),
                      Text(
                          'These were captured when the card was marked sold and can\'t be changed, since they\'re part of its permanent sale record.',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                              height: 1.4)),
                      SizedBox(height: 12.h),
                      Row(children: [
                        Expanded(
                            child: _readOnlyField(
                                'Shipping Charged',
                                controller.originalCard.shippingCharge > 0
                                    ? '\$${controller.originalCard.shippingCharge.toStringAsFixed(2)}'
                                    : 'None')),
                        SizedBox(width: 12.w),
                        Expanded(
                            child: _readOnlyField(
                                'Tax Charged',
                                controller.originalCard.taxCharged > 0
                                    ? '\$${controller.originalCard.taxCharged.toStringAsFixed(2)}'
                                    : 'None')),
                      ]),
                    ],
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
              child: Obx(() => GestureDetector(
                    onTap: controller.isSaving.value
                        ? null
                        : controller.saveChanges,
                    child: Container(
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Center(
                        child: controller.isSaving.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text('Save Changes',
                                style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8));

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));

  // Grayed-out, non-editable field — visually distinct from a real TextFormField
  // (no border, muted fill) so it reads clearly as "locked", not just disabled.
  Widget _readOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      SizedBox(height: 8.h),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(children: [
          Icon(Icons.lock_outline_rounded,
              color: AppColors.textMuted, size: 15.sp),
          SizedBox(width: 8.w),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);
  }
}
