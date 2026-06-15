import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/main.dart';

class AppTheme {
  static bool get isDark => darkModeNotifier.value;

  static Color get primary => const Color(0xFF10B981);
  static Color get primaryDark => const Color(0xFF006C49);
  static Color get brandNavy => const Color(0xFF0F172A);
  
  static Color get primaryLight => isDark 
      ? const Color(0xFF006C49).withValues(alpha: 0.2) 
      : const Color(0xFFE8F0E9);
  
  static Color get background => isDark ? const Color(0xFF0F172A) : const Color(0xFFF4FBF4);
  static Color get scaffoldBackground => isDark ? const Color(0xFF0F172A) : const Color(0xFFF4FBF4);
  static Color get surface => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF161D19);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF3C4A42);
  
  static Color get border => isDark ? const Color(0xFF334155) : const Color(0xFFBBCABF);
  
  static Color get success => const Color(0xFF10B981);
  static Color get error => const Color(0xFFBA1A1A);
  static Color get warning => const Color(0xFFF59E0B);

  static InputDecoration inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: textSecondary.withValues(alpha: 0.6),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1.5),
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: isDark ? [] : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.1,
  );
}
