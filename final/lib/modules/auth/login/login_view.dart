import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  LoginController get c => Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Form(
            key: c.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 52.h),

                // Brand mark
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.style_rounded, color: Colors.white, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hobby Watch',
                            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text('Know when to sell. Every time.',
                            style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 52.h),

                Text('Welcome back',
                    style: GoogleFonts.inter(fontSize: 30.sp, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.1)),
                SizedBox(height: 8.h),
                Text('Sign in to continue tracking your collection',
                    style: GoogleFonts.inter(fontSize: 14.sp, color: AppColors.textSecondary)),

                SizedBox(height: 40.h),

                _FieldLabel('Email Address'),
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

                _FieldLabel('Password'),
                SizedBox(height: 8.h),
                Obx(() => TextFormField(
                  controller: c.passwordController,
                  obscureText: c.obscurePassword.value,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14.sp),
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 19.sp),
                    suffixIcon: IconButton(
                      icon: Icon(
                        c.obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted, size: 19.sp,
                      ),
                      onPressed: c.togglePassword,
                    ),
                  ),
                )),

                SizedBox(height: 36.h),

                Obx(() => _PrimaryButton(
                  label: 'Sign In',
                  isLoading: c.isLoading.value,
                  onTap: c.login,
                )),

                SizedBox(height: 16.h),

                Center(
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                    child: Text('Forgot your password?',
                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                ),

                SizedBox(height: 24.h),

                Row(children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Text('or', style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textMuted)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ]),

                SizedBox(height: 28.h),

                Center(
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account?  ",
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14.sp),
                        children: [
                          TextSpan(
                            text: 'Create one',
                            style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('By signing in you agree to our ',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.terms),
                        child: Text('Terms',
                            style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                      Text(' & ',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.privacy),
                        child: Text('Privacy Policy',
                            style: GoogleFonts.inter(fontSize: 11.sp, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
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
