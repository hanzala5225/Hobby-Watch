import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  ForgotPasswordController get c => Get.find<ForgotPasswordController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Form(
            key: c.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Icon + header
                Container(
                  width: 56.w, height: 56.w,
                  decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16.r)),
                  child: Icon(Icons.lock_reset_rounded, color: Colors.white, size: 26.sp),
                ),
                SizedBox(height: 24.h),
                Text('Reset Password',
                    style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.1)),
                SizedBox(height: 8.h),
                Text('Enter your email and choose a new password.',
                    style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textSecondary)),

                SizedBox(height: 8.h),

                // Phase 1 notice
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16.sp),
                    SizedBox(width: 10.w),
                    Expanded(child: Text(
                      'Email verification will be added in a future update. For now, enter your registered email and new password.',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textSecondary, height: 1.4),
                    )),
                  ]),
                ),

                SizedBox(height: 32.h),

                // Email
                _label('Registered Email'),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: c.emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 19.sp),
                  ),
                ),

                SizedBox(height: 20.h),

                // New password
                _label('New Password'),
                SizedBox(height: 8.h),
                Obx(() => TextFormField(
                  controller: c.newPassController,
                  obscureText: c.obscureNew.value,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                    suffixIcon: IconButton(
                      icon: Icon(
                          c.obscureNew.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted, size: 19.sp),
                      onPressed: () => c.obscureNew.value = !c.obscureNew.value,
                    ),
                  ),
                )),

                SizedBox(height: 20.h),

                // Confirm password
                _label('Confirm New Password'),
                SizedBox(height: 8.h),
                Obx(() => TextFormField(
                  controller: c.confirmController,
                  obscureText: c.obscureConfirm.value,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                  validator: (v) => v != c.newPassController.text
                      ? 'Passwords do not match'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                    suffixIcon: IconButton(
                      icon: Icon(
                          c.obscureConfirm.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted, size: 19.sp),
                      onPressed: () => c.obscureConfirm.value = !c.obscureConfirm.value,
                    ),
                  ),
                )),

                SizedBox(height: 36.h),

                // Submit button
                Obx(() => GestureDetector(
                  onTap: c.isLoading.value ? null : c.resetPassword,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 54.h,
                    decoration: BoxDecoration(
                      gradient: c.isLoading.value ? null : AppColors.heroGradient,
                      color: c.isLoading.value ? AppColors.border : null,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: c.isLoading.value ? [] : [
                        BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: c.isLoading.value
                          ? SizedBox(width: 22.w, height: 22.w,
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
                          : Text('Reset Password',
                          style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                )),

                SizedBox(height: 24.h),

                Center(
                  child: GestureDetector(
                    onTap: Get.back,
                    child: Text('Back to Sign In',
                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}
