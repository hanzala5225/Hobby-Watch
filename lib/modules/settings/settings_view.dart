import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../routes/app_routes.dart';
import 'settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Settings', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp), onPressed: Get.back),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          // ── User card ────────────────────────────────────────────────────
          Obx(() {
            final u = controller.user.value;
            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(children: [
                Container(
                  width: 52.w, height: 52.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: Center(child: Text(u?.initials ?? '?',
                      style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                SizedBox(width: 14.w),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u?.displayName ?? '—',
                        style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 3.h),
                    Text(u?.email ?? '—',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
              ]),
            );
          }),

          // ── Pending deletion warning ──────────────────────────────────────
          Obx(() {
            final deleteAt = controller.scheduledDeleteAt.value;
            if (deleteAt == null) return const SizedBox();
            final remaining = deleteAt.difference(DateTime.now());
            final hoursLeft = remaining.inHours;
            final minsLeft  = remaining.inMinutes % 60;
            final timeStr   = hoursLeft > 0 ? '${hoursLeft}h ${minsLeft}m' : '< 1 hour';
            return Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.loss.withOpacity(0.3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('⚠️ Account Deletion Scheduled',
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.loss)),
                    SizedBox(height: 4.h),
                    Text('Your account will be permanently deleted in $timeStr.',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4)),
                    SizedBox(height: 5.h),
                    Text('To cancel: sign out and log back in before the timer expires.',
                        style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted, height: 1.4)),
                  ])),
                ]),
              ),
            );
          }),

          SizedBox(height: 28.h),
          _sectionLabel('Account'),
          _tile(Icons.person_outline_rounded, 'Edit Profile', 'Update your name',
                  () => _showProfileSheet(context)),
          SizedBox(height: 8.h),
          _tile(Icons.lock_outline_rounded, 'Change Password', 'Update your password',
                  () => _showChangePasswordSheet(context)),

          SizedBox(height: 24.h),

          // ── App ───────────────────────────────────────────────────────────
          _sectionLabel('App'),
          _tile(Icons.article_outlined, 'Terms & Conditions', 'Read our terms',
                  () => Get.toNamed(AppRoutes.terms)),
          SizedBox(height: 8.h),
          _tile(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we handle your data',
                  () => Get.toNamed(AppRoutes.privacy)),

          SizedBox(height: 24.h),

          // ── Danger Zone ───────────────────────────────────────────────────
          _sectionLabel('Account Actions'),
          _tile(Icons.logout_rounded, 'Sign Out', 'Log out of this device',
              controller.logout, color: AppColors.loss),
          SizedBox(height: 8.h),
          _tile(Icons.delete_forever_rounded, 'Delete Account', '24-hour grace period to undo',
              controller.requestDeleteAccount, color: AppColors.loss),

          SizedBox(height: 40.h),
          Center(child: Text('Hobby Watch v1.0.07',
              style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textMuted))),
          SizedBox(height: 6.h),
          Center(child: Text('Sports card profit tracking',
              style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted))),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.8)),
    );
  }

  Widget _tile(IconData icon, String label, String subtitle, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 38.w, height: 38.w,
            decoration: BoxDecoration(
              color: color != null ? color.withOpacity(0.1) : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 19.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary)),
              SizedBox(height: 2.h),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18.sp),
        ]),
      ),
    );
  }

  // ── Profile bottom sheet ─────────────────────────────────────────────────
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(controller: controller),
    );
  }

  // ── Change password bottom sheet ─────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(controller: controller),
    );
  }
}

// ── Profile Sheet ────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final SettingsController controller;
  const _ProfileSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        child: Form(
          key: controller.profileFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40.w, height: 4.h,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r)))),
              SizedBox(height: 20.h),
              Text('Edit Profile',
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
              SizedBox(height: 20.h),
              Text('Full Name', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                decoration: InputDecoration(
                  hintText: 'Your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 19.sp),
                ),
              ),
              SizedBox(height: 24.h),
              Obx(() => GestureDetector(
                onTap: controller.isLoading.value ? null : controller.saveProfile,
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: controller.isLoading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Changes', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Change Password Sheet ─────────────────────────────────────────────────────
class _ChangePasswordSheet extends StatelessWidget {
  final SettingsController controller;
  const _ChangePasswordSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        child: Form(
          key: controller.passwordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40.w, height: 4.h,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r)))),
              SizedBox(height: 20.h),
              Text('Change Password',
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
              SizedBox(height: 20.h),

              // Current password
              Obx(() => TextFormField(
                controller: controller.currentPassController,
                obscureText: controller.obscureCurrent.value,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                  suffixIcon: IconButton(
                    icon: Icon(controller.obscureCurrent.value ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 19.sp),
                    onPressed: () => controller.obscureCurrent.value = !controller.obscureCurrent.value,
                  ),
                ),
              )),
              SizedBox(height: 14.h),

              // New password
              Obx(() => TextFormField(
                controller: controller.newPassController,
                obscureText: controller.obscureNew.value,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                decoration: InputDecoration(
                  hintText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                  suffixIcon: IconButton(
                    icon: Icon(controller.obscureNew.value ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 19.sp),
                    onPressed: () => controller.obscureNew.value = !controller.obscureNew.value,
                  ),
                ),
              )),
              SizedBox(height: 14.h),

              // Confirm new password
              Obx(() => TextFormField(
                controller: controller.confirmPassController,
                obscureText: controller.obscureConfirm.value,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                validator: (v) => v != controller.newPassController.text ? 'Passwords do not match' : null,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                  suffixIcon: IconButton(
                    icon: Icon(controller.obscureConfirm.value ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 19.sp),
                    onPressed: () => controller.obscureConfirm.value = !controller.obscureConfirm.value,
                  ),
                ),
              )),
              SizedBox(height: 24.h),

              Obx(() => GestureDetector(
                onTap: controller.isLoading.value ? null : controller.changePassword,
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: controller.isLoading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Update Password', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}