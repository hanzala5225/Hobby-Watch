import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.sp), onPressed: Get.back),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('Privacy Policy'),
            _body('Last updated: June 2026'),
            SizedBox(height: 20.h),
            _section('1. Information We Collect'),
            _body('We collect the following information:\n\n• Account information: email address, full name, and encrypted password\n• Card collection data: card names, purchase prices, target margins, and related metadata\n• Device information: FCM push notification token for delivering price alerts\n• Usage data: app interactions for improving the service'),
            _section('2. How We Use Your Information'),
            _body('We use your information to:\n\n• Provide and maintain the Hobby Watch service\n• Send push notifications when your cards reach target profit margins\n• Improve the App and develop new features\n• Communicate important updates about the service'),
            _section('3. Data Storage and Security'),
            _body('Your data is stored securely on cloud servers. We use industry-standard encryption for data in transit (HTTPS/TLS) and at rest. Passwords are hashed using bcrypt and are never stored in plain text. We do not sell your personal information to third parties.'),
            _section('4. Third-Party Services'),
            _body('The App uses the following third-party services:\n\n• eBay API: to fetch current market pricing data (no personal data is shared)\n• Firebase Cloud Messaging: to deliver push notifications to your device\n• Supabase (PostgreSQL): for secure database storage\n• Railway: for backend hosting infrastructure'),
            _section('5. Data Retention'),
            _body('We retain your data for as long as your account is active. When you delete your account, we will permanently delete all your personal data within 24 hours of the deletion request being confirmed. Some anonymized usage statistics may be retained for analytics purposes.'),
            _section('6. Push Notifications'),
            _body('We send push notifications when cards in your collection reach your specified target profit margin. You can disable push notifications at any time through your device\'s notification settings. Note that disabling notifications will prevent you from receiving price alerts.'),
            _section('7. Your Rights'),
            _body('You have the right to:\n\n• Access the personal data we hold about you\n• Correct inaccurate data\n• Request deletion of your data (via Settings > Delete Account)\n• Object to processing of your data\n• Data portability upon request'),
            _section('8. Children\'s Privacy'),
            _body('The App is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe we have inadvertently collected such information, please contact us immediately.'),
            _section('9. Changes to This Policy'),
            _body('We may update this Privacy Policy from time to time. We will notify you of significant changes through the App. Continued use after changes constitutes acceptance of the new policy.'),
            _section('10. Contact Us'),
            _body('For privacy-related questions or to exercise your rights, contact us at:\n\nprivacy@hobbywatch.app'),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Text(text, style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
  Widget _section(String text) => Padding(
    padding: EdgeInsets.only(top: 20.h, bottom: 8.h),
    child: Text(text, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  );
  Widget _body(String text) => Text(text, style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.6));
}
