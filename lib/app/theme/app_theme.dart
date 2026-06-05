import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOBBY WATCH COLOR PALETTE
// Primary:  #0C2473 (deep navy blue)
// Accent:   #009286 (teal green)
// Neutral:  #B2B2B2 (platinum gray)
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Brand colors (Tim's spec)
  static const Color primary      = Color(0xFF0C2473);
  static const Color primaryLight = Color(0xFF1A3590);
  static const Color primaryDark  = Color(0xFF081A55);
  static const Color accent       = Color(0xFF009286);
  static const Color accentLight  = Color(0xFF00ADA0);
  static const Color accentDark   = Color(0xFF007870);
  static const Color neutral      = Color(0xFFB2B2B2);

  // Backgrounds
  static const Color bgDark       = Color(0xFFF5F7FA);
  static const Color bgCard       = Color(0xFFFFFFFF);
  static const Color bgSurface    = Color(0xFFEDF0F7);
  static const Color bgInput      = Color(0xFFF0F2F8);

  // Status
  static const Color profit       = Color(0xFF009286);   // uses accent for profit green
  static const Color loss         = Color(0xFFD63031);
  static const Color warning      = Color(0xFFE17055);

  // Text
  static const Color textPrimary   = Color(0xFF0C2473);   // navy on white
  static const Color textSecondary = Color(0xFF5A6A8A);
  static const Color textMuted     = Color(0xFFB2B2B2);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // Borders
  static const Color border        = Color(0xFFDDE3EF);
  static const Color divider       = Color(0xFFF0F2F8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0C2473), Color(0xFF1A3590)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF009286), Color(0xFF00ADA0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0C2473), Color(0xFF009286)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF009286), Color(0xFF007870)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scanGradient = LinearGradient(
    colors: [Color(0xFF060E2A), Color(0xFF0C2473)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
        error: AppColors.loss,
        onPrimary: AppColors.textOnDark,
        onSecondary: AppColors.textOnDark,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: AppColors.textPrimary),
          bodyMedium:    TextStyle(color: AppColors.textSecondary),
          bodySmall:     TextStyle(color: AppColors.textMuted),
          labelLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.loss),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}
