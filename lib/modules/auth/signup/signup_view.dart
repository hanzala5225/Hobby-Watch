import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
                    onPressed: Get.back,
                  ),
                  Text('Create Account',
                      style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28.w, 24.h, 28.w, 0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join Hobby Watch',
                          style: GoogleFonts.inter(fontSize: 26.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      SizedBox(height: 6.h),
                      Text('Start tracking your collection today',
                          style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textSecondary)),

                      SizedBox(height: 36.h),

                      _FieldLabel('Full Name'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                        decoration: InputDecoration(
                          hintText: 'John Smith',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 19.sp),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      _FieldLabel('Email Address'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 19.sp),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      _FieldLabel('Password'),
                      SizedBox(height: 8.h),
                      Obx(() => TextFormField(
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                        validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textMuted, size: 19.sp,
                            ),
                            onPressed: controller.togglePassword,
                          ),
                        ),
                      )),

                      SizedBox(height: 18.h),

                      _FieldLabel('Confirm Password'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: controller.confirmController,
                        obscureText: true,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                        validator: (v) => v != controller.passwordController.text ? 'Passwords do not match' : null,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Terms checkbox — clean, no decoration mess
                      Obx(() => GestureDetector(
                        onTap: controller.toggleTerms,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22.w,
                              height: 22.w,
                              decoration: BoxDecoration(
                                color: controller.acceptedTerms.value ? AppColors.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: controller.acceptedTerms.value ? AppColors.accent : AppColors.border,
                                  width: 1.8,
                                ),
                              ),
                              child: controller.acceptedTerms.value
                                  ? Icon(Icons.check, color: Colors.white, size: 13.sp)
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Wrap(
                                children: [
                                  Text('I agree to the ',
                                      style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5)),
                                  GestureDetector(
                                    onTap: () => Get.toNamed(AppRoutes.terms),
                                    child: Text('Terms & Conditions',
                                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.accent, fontWeight: FontWeight.w600, height: 1.5)),
                                  ),
                                  Text(' and ',
                                      style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5)),
                                  GestureDetector(
                                    onTap: () => Get.toNamed(AppRoutes.privacy),
                                    child: Text('Privacy Policy',
                                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.accent, fontWeight: FontWeight.w600, height: 1.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                      SizedBox(height: 32.h),

                      Obx(() => _PrimaryButton(
                        label: 'Create Account',
                        isLoading: controller.isLoading.value,
                        onTap: controller.register,
                      )),

                      SizedBox(height: 24.h),

                      Center(
                        child: GestureDetector(
                          onTap: Get.back,
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account?  ',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14.sp),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
                                  style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54.h,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.heroGradient,
          color: isLoading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: isLoading ? [] : [
            BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(width: 22.w, height: 22.w,
              child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
              : Text(label,
              style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}