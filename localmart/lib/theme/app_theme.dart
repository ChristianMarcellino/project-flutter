import 'package:flutter/material.dart';
import 'package:localmart/main.dart';

class AppTheme {
  static bool get isDark => darkModeNotifier.value;

  static Color get primary => const Color(0xFF2563EB);
  static Color get primaryLight => isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEEF3FF);
  
  static Color get background => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get scaffoldBackground => isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  static Color get surface => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  
  static Color get border => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  
  static Color get success => const Color(0xFF10B981);
  static Color get error => const Color(0xFFF43F5E);
  static Color get warning => const Color(0xFFF59E0B);

  static InputDecoration inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textSecondary),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary),
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border),
    boxShadow: isDark ? [] : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static TextStyle get h1 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.8,
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get body => TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.5,
  );
}
