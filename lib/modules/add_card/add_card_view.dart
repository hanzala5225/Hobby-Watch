import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import 'add_card_controller.dart';

class AddCardView extends GetView<AddCardController> {
  const AddCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Add Card', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: Get.back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Obx(() => Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Row(
                children: List.generate(2, (i) {
                  final isActive = i == controller.currentStep.value;
                  final isDone   = i < controller.currentStep.value;
                  return Expanded(
                    child: Row(children: [
                      Expanded(child: Container(
                        height: 4.h,
                        margin: EdgeInsets.only(right: i < 1 ? 6.w : 0),
                        decoration: BoxDecoration(
                          gradient: isDone || isActive ? AppColors.heroGradient : null,
                          color:    isDone || isActive ? null : AppColors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      )),
                    ]),
                  );
                }),
              ),
            )),

            Expanded(
              child: Obx(() => SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: controller.currentStep.value == 0 ? _step1() : _step2(),
              )),
            ),

            // Bottom nav
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
              child: Obx(() => Row(
                children: [
                  if (controller.currentStep.value > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: Size(0, 52.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Back', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: controller.isLoading.value ? null : (controller.currentStep.value < 1 ? controller.nextStep : controller.saveCard),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: controller.isLoading.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(controller.currentStep.value < 1 ? 'Continue' : 'Save Card',
                              style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text('Card Details', style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Text('Enter basic card information', style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textSecondary)),
        SizedBox(height: 28.h),
        _label('Player Name *'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.playerNameController, textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: 'e.g. Michael Jordan', prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20.sp))),
        SizedBox(height: 18.h),
        _label('Year *'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.yearController, keyboardType: TextInputType.number, maxLength: 4,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: '1996', prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 20.sp), counterText: '')),
        SizedBox(height: 18.h),
        _label('Brand (optional)'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.brandController, textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: 'e.g. Topps, Panini', prefixIcon: Icon(Icons.business_outlined, color: AppColors.textMuted, size: 20.sp))),
        SizedBox(height: 18.h),
        _label('Set / Series (optional)'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.setNameController, textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: 'e.g. Topps Chrome', prefixIcon: Icon(Icons.layers_outlined, color: AppColors.textMuted, size: 20.sp))),
        SizedBox(height: 18.h),
        _label('Parallel / Variety (optional)'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.parallelController, textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: 'e.g. Silver, Gold Refractor', prefixIcon: Icon(Icons.auto_awesome_outlined, color: AppColors.textMuted, size: 20.sp))),
        SizedBox(height: 18.h),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Card # (optional)'),
            SizedBox(height: 8.h),
            TextFormField(controller: controller.cardNumberController,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                decoration: InputDecoration(hintText: '#139')),
          ])),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Grade (optional)'),
            SizedBox(height: 8.h),
            TextFormField(controller: controller.gradeController, textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                decoration: const InputDecoration(hintText: 'PSA 10')),
          ])),
        ]),
        SizedBox(height: 18.h),
        _label('eBay Search Query (optional)'),
        SizedBox(height: 8.h),
        TextFormField(controller: controller.ebaySearchController,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(hintText: 'e.g. 1996 Topps Michael Jordan PSA 10',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20.sp))),
        SizedBox(height: 6.h),
        Text('Auto-filled from the details above — feel free to edit it.',
            style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text('Pricing', style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Text('What did you pay and what\'s your target?', style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textSecondary)),
        SizedBox(height: 28.h),
        _label('Purchase Price (USD) *'),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller.purchasePriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money, color: AppColors.textMuted, size: 20.sp)),
        ),
        SizedBox(height: 18.h),
        _label('Target Profit Margin (%)'),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller.targetMarginController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(hintText: '30',
              prefixIcon: Icon(Icons.trending_up_rounded, color: AppColors.textMuted, size: 20.sp),
              suffixText: '%', suffixStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14.sp)),
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.07), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.accent, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(child: Text('eBay fees (~13.25%) are automatically deducted from profit calculations.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4))),
          ]),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}