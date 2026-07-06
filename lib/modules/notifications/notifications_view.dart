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
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.sp),
          onPressed: Get.back,
        ),
        actions: [
          Obx(() {
            final hasUnread = controller.notifications.any(
                  (n) => !(n['isRead'] as bool? ?? false),
            );
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: controller.markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
          );
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 52.sp,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No notifications yet',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "You'll be notified when a card hits your target margin.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (_, i) {
              final n = controller.notifications[i];

              final isRead = (n['isRead'] ?? n['is_read']) as bool? ?? false;

              // createdAt / created_at
              final rawDate = n['createdAt'] ?? n['created_at'];
              final date = rawDate != null
                  ? DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now()
                  : DateTime.now();

              final title = (n['title'] as String?)?.isNotEmpty == true
                  ? n['title'] as String
                  : 'Alert';

              final body = n['body'] as String? ?? '';

              // Notification type for icon selection
              final type = n['notificationType'] ?? n['notification_type'] ?? 'campaign';
              final icon = _iconForType(type as String);

              return _NotificationTile(
                title: title,
                body: body,
                date: date,
                isRead: isRead,
                icon: icon,
                onTap: () => controller.markRead(n['id'] as String?),
              );
            },
          ),
        );
      }),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'target_reached' => Icons.flag_rounded,
      'price_up'       => Icons.trending_up_rounded,
      'price_down'     => Icons.trending_down_rounded,
      _                => Icons.notifications_active_rounded, // campaign or unknown
    };
  }
}

// ─── Extracted tile widget for cleanliness ────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
    required this.date,
    required this.isRead,
    required this.icon,
    this.onTap,
  });

  final String   title;
  final String   body;
  final DateTime date;
  final bool     isRead;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.bgCard
              : AppColors.accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isRead
                ? AppColors.border
                : AppColors.accent.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 12.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Text(
                    DateFormat('MMM d, y  h:mm a').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Padding(
                padding: EdgeInsets.only(top: 4.h, left: 6.w),
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}