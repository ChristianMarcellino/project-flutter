import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscurePassword : false,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            errorText: errorText?.isNotEmpty == true ? errorText : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF6B7280),
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
