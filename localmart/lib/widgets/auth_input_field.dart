import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
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
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            errorText: errorText?.isNotEmpty == true ? errorText : null,
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
