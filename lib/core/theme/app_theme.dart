import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches the shared HTML reference (Kharcha).
class AppColors {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161923);
  static const surface2 = Color(0xFF1E2433);
  static const card = Color(0xFF161923);
  static const border = Color(0xFF2A3040);
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryGlow = Color(0x226366F1);
  /// Aliases for older widgets
  static const accent = primaryLight;
  static const accentGlow = primaryGlow;
  static const safe = Color(0xFF22C55E);
  static const safeDim = Color(0x2216A34A);
  static const warn = Color(0xFFF59E0B);
  static const warnDim = Color(0x22D97706);
  static const danger = Color(0xFFEF4444);
  static const dangerDim = Color(0x22DC2626);
  static const text = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF64748B);
  static const textSoft = Color(0xFF94A3B8);
  static const divider = border;

  static const textPrimary = text;
  static const textSecondary = textSoft;
  static const credit = safe;
  static const debit = danger;
}

class AppTheme {
  static TextStyle mono(double size, {FontWeight w = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: w,
        color: AppColors.text,
        letterSpacing: -0.5,
      );

  static ThemeData get darkTheme {
    final base = GoogleFonts.soraTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: AppColors.bg,
        onSurface: AppColors.text,
      ),
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(color: AppColors.text),
        headlineMedium: base.headlineMedium?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.bodyLarge?.copyWith(color: AppColors.text),
        bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSoft),
        bodySmall: base.bodySmall?.copyWith(color: AppColors.textMuted),
        labelLarge: base.labelLarge?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixStyle: const TextStyle(
          color: AppColors.textSoft,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
