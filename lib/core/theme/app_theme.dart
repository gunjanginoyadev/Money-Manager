import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark theme aligned with the Money Manager HTML reference (mint accent, charcoal surfaces).
class AppColors {
  static const bg = Color(0xFF0B0D11);
  static const surface = Color(0xFF13161D);
  static const surface2 = Color(0xFF1A1E28);
  static const card = Color(0xFF13161D);
  /// rgba(255,255,255,0.06)
  static const border = Color(0x0FFFFFFF);

  static const primary = Color(0xFF6EE7B7);
  static const primaryLight = Color(0xFF86EFAC);
  static const primaryGlow = Color(0x226EE7B7);
  /// Text/icon on mint (e.g. + FAB).
  static const onAccent = Color(0xFF0B0D11);

  static const accent = primaryLight;
  static const accentGlow = primaryGlow;

  static const safe = Color(0xFF6EE7B7);
  static const safeDim = Color(0x226EE7B7);
  static const warn = Color(0xFFF59E0B);
  static const warnDim = Color(0x22D97706);
  static const danger = Color(0xFFF87171);
  static const dangerDim = Color(0x22F87171);

  /// Savings progress accent (purple).
  static const savings = Color(0xFFA78BFA);

  static const text = Color(0xFFF0F2F7);
  static const textMuted = Color(0xFF6B7280);
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
        secondary: AppColors.warn,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: AppColors.onAccent,
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
          foregroundColor: AppColors.onAccent,
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
