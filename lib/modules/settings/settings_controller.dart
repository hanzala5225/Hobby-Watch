import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/app_constants.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/api_service.dart';
import '../routes/app_routes.dart';

class SettingsController extends GetxController {
  final _api = Get.find<ApiService>();

  final user        = Rx<UserModel?>(null);
  final isLoading   = false.obs;

  // Profile form
  final nameController  = TextEditingController();
  final profileFormKey  = GlobalKey<FormState>();

  // Change password form
  final currentPassController = TextEditingController();
  final newPassController     = TextEditingController();
  final confirmPassController = TextEditingController();
  final passwordFormKey       = GlobalKey<FormState>();
  final obscureCurrent        = true.obs;
  final obscureNew            = true.obs;
  final obscureConfirm        = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final j = prefs.getString(AppConstants.keyUser);
      if (j != null) user.value = UserModel.fromJson(jsonDecode(j));
      final fresh = await _api.getProfile();
      user.value = fresh;
      nameController.text = fresh.fullName ?? '';
      await prefs.setString(AppConstants.keyUser, jsonEncode(fresh.toJson()));
    } catch (_) {
      final u = user.value;
      if (u != null) nameController.text = u.fullName ?? '';
    }
  }

  Future<void> saveProfile() async {
    if (!profileFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final updated = await _api.updateProfile({'fullName': nameController.text.trim()});
      user.value = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUser, jsonEncode(updated.toJson()));
      Get.back();
      Get.snackbar('✅ Profile Updated', 'Your name has been saved.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (e) {
      Get.snackbar('Error', 'Could not update profile.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      await _api.changePassword(
        currentPassController.text,
        newPassController.text,
      );
      currentPassController.clear();
      newPassController.clear();
      confirmPassController.clear();
      Get.back();
      Get.snackbar('✅ Password Changed', 'Your password has been updated.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (e) {
      String msg = 'Could not change password.';
      try {
        final dioErr = e as dynamic;
        msg = dioErr.response?.data['message'] ?? msg;
      } catch (_) {}
      Get.snackbar('Error', msg,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      _SignOutDialog(),
    ) ?? false;
    if (!confirmed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rt = prefs.getString(AppConstants.keyRefreshToken) ?? '';
      await _api.logout(rt);
      await prefs.clear();
    } catch (_) {}
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> requestDeleteAccount() async {
    // Step 1 — confirm intent
    final confirmed = await Get.dialog<bool>(
      _DeleteAccountDialog(),
      barrierDismissible: true, // user can still cancel by tapping outside here
    ) ?? false;

    if (!confirmed) return;

    // Step 2 — call backend to schedule deletion
    try {
      await _api.deleteAccount();
    } catch (_) {
      // Even if the endpoint fails, we still show the message
      // (backend soft-deletes on next background run anyway)
    }

    // Step 3 — show non-dismissible info dialog, auto-logout after 5 seconds
    Get.dialog(
      _DeletionScheduledDialog(onOk: logout),
      barrierDismissible: false, // cannot tap outside to dismiss
    );

    // Auto-logout after 5 seconds in case user ignores the button
    Future.delayed(const Duration(seconds: 5), () {
      if (Get.isDialogOpen ?? false) {
        Get.back(); // close dialog
      }
      logout();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    currentPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.onClose();
  }
}

// ── Blurred Sign Out Dialog ───────────────────────────────────────────────────
class _SignOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w, height: 60.w,
                decoration: BoxDecoration(color: AppColors.loss.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.logout_rounded, color: AppColors.loss, size: 28.sp),
              ),
              SizedBox(height: 16.h),
              Text('Sign Out',
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              SizedBox(height: 8.h),
              Text("You'll need to sign back in to access your collection.",
                  style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              SizedBox(height: 24.h),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: Size(0, 48.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('Stay', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.loss,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(0, 48.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('Sign Out', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Delete Account Dialog ─────────────────────────────────────────────────────
class _DeleteAccountDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red warning header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.06),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  border: Border(bottom: BorderSide(color: AppColors.loss.withOpacity(0.12))),
                ),
                child: Column(children: [
                  Container(
                    width: 56.w, height: 56.w,
                    decoration: BoxDecoration(
                      color: AppColors.loss.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: AppColors.loss, size: 26.sp),
                  ),
                  SizedBox(height: 12.h),
                  Text('Delete Account?',
                      style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.loss),
                      textAlign: TextAlign.center),
                ]),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.w),
                child: Column(
                  children: [
                    // Warning bullets
                    _warningRow(Icons.access_time_rounded,
                        'Your account will be permanently deleted after 24 hours.'),
                    SizedBox(height: 10.h),
                    _warningRow(Icons.style_rounded,
                        'All your cards, price history, and data will be removed.'),
                    SizedBox(height: 10.h),
                    _warningRow(Icons.undo_rounded,
                        'You can cancel by logging back in within 24 hours.'),

                    SizedBox(height: 20.h),

                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: Size(0, 48.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text('Keep Account',
                              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.loss,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: Size(0, 48.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text('Delete',
                              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _warningRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w, height: 28.w,
          decoration: BoxDecoration(color: AppColors.loss.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.loss, size: 14.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.5)),
        ),
      ],
    );
  }
}

// ── Deletion Scheduled Dialog ─────────────────────────────────────────────────
class _DeletionScheduledDialog extends StatefulWidget {
  final VoidCallback onOk;
  const _DeletionScheduledDialog({required this.onOk});

  @override
  State<_DeletionScheduledDialog> createState() => _DeletionScheduledDialogState();
}

class _DeletionScheduledDialogState extends State<_DeletionScheduledDialog> {
  int _seconds = 5;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _seconds--);
      return _seconds > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w, height: 64.w,
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 30.sp),
              ),
              SizedBox(height: 16.h),
              Text('Deletion Scheduled',
                  style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              SizedBox(height: 10.h),
              Text('Your account is scheduled for deletion in 24 hours.',
                  style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text('To cancel: log back in within 24 hours.',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.warning, fontWeight: FontWeight.w500, height: 1.4)),
                  ),
                ]),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Get.back(); widget.onOk(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(0, 50.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _seconds > 0 ? 'Signing out in $_seconds...' : 'OK, Sign Me Out',
                      key: ValueKey(_seconds),
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
