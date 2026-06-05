import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text('Terms & Conditions', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.sp), onPressed: Get.back),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('Terms and Conditions'),
            _body('Last updated: June 2026'),
            SizedBox(height: 20.h),
            _section('1. Acceptance of Terms'),
            _body('By downloading, installing, or using Hobby Watch ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the App.'),
            _section('2. Description of Service'),
            _body('Hobby Watch is a sports card collection tracking application that provides estimated market price data based on active eBay listings. The App is intended to help collectors monitor the potential resale value of their sports card collections.'),
            _section('3. Price Data Disclaimer'),
            _body('Price data displayed in the App is sourced from publicly available eBay listings and represents estimated market prices only. This data is NOT guaranteed to be accurate, complete, or current. Hobby Watch does not guarantee any specific sale price for any card. Always conduct your own research before making buying or selling decisions.'),
            _section('4. User Accounts'),
            _body('You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to terminate accounts that violate these terms.'),
            _section('5. Account Deletion'),
            _body('You may request deletion of your account at any time through the Settings menu. Upon requesting deletion, you have a 24-hour grace period to cancel the request by logging back into the App. After 24 hours, your account and all associated data will be permanently deleted and cannot be recovered.'),
            _section('6. Prohibited Uses'),
            _body('You may not use the App to: (a) violate any laws or regulations; (b) infringe on intellectual property rights; (c) transmit harmful or malicious content; (d) attempt to gain unauthorized access to the App or its systems; (e) use the App for any commercial purpose without written permission.'),
            _section('7. Limitation of Liability'),
            _body('Hobby Watch and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App, including any financial losses resulting from reliance on price data provided by the App.'),
            _section('8. Changes to Terms'),
            _body('We reserve the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the new Terms. We will notify users of material changes through the App.'),
            _section('9. Governing Law'),
            _body('These Terms are governed by the laws of the United States. Any disputes shall be resolved in the courts of competent jurisdiction.'),
            _section('10. Contact'),
            _body('For questions about these Terms, contact us at support@hobbywatch.app'),
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
