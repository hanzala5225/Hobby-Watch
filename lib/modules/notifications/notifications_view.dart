import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Notifications', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.sp), onPressed: Get.back),
        actions: [
          TextButton(onPressed: controller.markAllRead, child: Text('Mark all read', style: GoogleFonts.inter(color: AppColors.accent, fontSize: 13.sp, fontWeight: FontWeight.w500))),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5));
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none_rounded, size: 52.sp, color: AppColors.textMuted),
              SizedBox(height: 16.h),
              Text('No notifications yet', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              SizedBox(height: 8.h),
              Text('You\'ll be notified when a card hits your target margin.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted)),
            ]),
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (_, i) {
              final n = controller.notifications[i];
              final isRead = n['isRead'] ?? false;
              final date = n['createdAt'] != null ? DateTime.parse(n['createdAt']).toLocal() : DateTime.now();
              return Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.bgCard : AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: isRead ? AppColors.border : AppColors.accent.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w, height: 40.w,
                      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(10.r)),
                      child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n['title'] ?? 'Alert', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        SizedBox(height: 4.h),
                        Text(n['body'] ?? '', style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4)),
                        SizedBox(height: 6.h),
                        Text(DateFormat('MMM d, y h:mm a').format(date), style: GoogleFonts.inter(fontSize: 10.sp, color: AppColors.textMuted)),
                      ]),
                    ),
                    if (!isRead) Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
