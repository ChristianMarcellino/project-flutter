import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/auth_input_field.dart';
import 'package:localmart/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await authService.resetPassword(email: _emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent! Check your inbox."),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text("Forgot Password", style: AppTheme.h1),
              const SizedBox(height: 8),

              Text(
                "Enter your email to receive a reset link",
                style: AppTheme.body,
              ),

              const SizedBox(height: 40),

              AuthInputField(
                label: "Email",
                hint: "your@email.com",
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              CustomButton(
                onPressed: resetPassword,
                text: "Send Reset Link",
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    "Back to Login",
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
