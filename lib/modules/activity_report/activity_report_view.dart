import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import 'activity_report_controller.dart';

class ActivityReportView extends GetView<ActivityReportController> {
  const ActivityReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Activity Report',
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: controller.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 40.h),
            child: Obx(() {
              final a = controller.activitySummary.value;
              final range = controller.selectedRange.value;

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cards you bought and sold in the selected time range.',
                    style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary)),
                SizedBox(height: 16.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _rangeChip('Year to Date', 'ytd', range),
                    SizedBox(width: 8.w),
                    _rangeChip('This Month', 'month', range),
                    SizedBox(width: 8.w),
                    _rangeChip('This Quarter', 'quarter', range),
                    SizedBox(width: 8.w),
                    _rangeChip('This Year', 'year', range),
                  ]),
                ),
                SizedBox(height: 24.h),

                if (controller.isLoading.value)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.h),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5)),
                  )
                else if (controller.loadFailed.value)
                  _messageCard(
                    icon: Icons.wifi_off_rounded,
                    title: 'Couldn\'t load activity',
                    subtitle: 'Check your connection and try again.',
                    actionLabel: 'Retry',
                    onAction: controller.load,
                  )
                else if (a == null || (a.cardsAdded == 0 && a.cardsSold == 0))
                    _messageCard(
                      icon: Icons.inbox_outlined,
                      title: 'No activity yet',
                      subtitle: 'No cards were bought or sold in this period.',
                    )
                  else ...[
                      _statCard(
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Invested',
                        value: fmt.format(a.totalInvestedInPeriod),
                        sublabel: '${a.cardsAdded} card${a.cardsAdded == 1 ? '' : 's'} added',
                        valueColor: AppColors.primary,
                      ),
                      SizedBox(height: 12.h),
                      _statCard(
                        icon: Icons.sell_rounded,
                        label: 'Realized Profit',
                        value: fmt.format(a.totalProfitInPeriod),
                        sublabel: '${a.cardsSold} card${a.cardsSold == 1 ? '' : 's'} sold · ${fmt.format(a.totalRevenueInPeriod)} revenue',
                        valueColor: a.totalProfitInPeriod >= 0 ? AppColors.profit : AppColors.loss,
                      ),
                      SizedBox(height: 12.h),
                      _statCard(
                        icon: Icons.trending_up_rounded,
                        label: 'ROI',
                        value: a.roiPercentInPeriod != null ? '${a.roiPercentInPeriod! >= 0 ? "+" : ""}${a.roiPercentInPeriod!.toStringAsFixed(1)}%' : '—',
                        sublabel: 'Return on the purchase price of cards sold in this period',
                        valueColor: (a.roiPercentInPeriod ?? 0) >= 0 ? AppColors.profit : AppColors.loss,
                      ),
                    ],
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _rangeChip(String label, String value, String selected) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => controller.setRange(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: isActive ? AppColors.accent.withOpacity(0.15) : AppColors.bgCard,
          border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600,
            color: isActive ? AppColors.accent : AppColors.textSecondary)),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    required Color valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44.w, height: 44.w,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: valueColor.withOpacity(0.12)),
          child: Icon(icon, color: valueColor, size: 22.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary)),
            SizedBox(height: 4.h),
            Text(value, style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: valueColor)),
            SizedBox(height: 4.h),
            Text(sublabel, style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(icon, size: 40.sp, color: AppColors.textMuted),
        SizedBox(height: 14.h),
        Text(title, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Text(subtitle, textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary)),
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: 16.h),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ),
        ],
      ]),
    );
  }
}