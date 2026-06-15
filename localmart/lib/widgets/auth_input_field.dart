import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/theme/app_theme.dart';

class AuthInputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscurePassword;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.obscurePassword = false,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscurePassword : false,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            errorText: errorText?.isNotEmpty == true ? errorText : null,
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
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
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.error, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
