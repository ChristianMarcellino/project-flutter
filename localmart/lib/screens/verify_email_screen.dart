import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  int _cooldownSeconds = 0;

  Future<void> startCooldown() async {
    setState(() => _cooldownSeconds = 60);
    while (_cooldownSeconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _cooldownSeconds--);
    }
  }

  Future<void> resendEmail() async {
    final user = authService.currentUser;
    if (user == null) return;
    setState(() => _isSending = true);
    try {
      await user.sendEmailVerification();
      startCooldown();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> checkStatus() async {
    final user = authService.currentUser;
    if (user == null) return;
    setState(() => _isChecking = true);
    await user.reload();
    if (mounted) setState(() => _isChecking = false);
    if (authService.currentUser?.emailVerified ?? false) {
      if (mounted) context.go('/');
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not verified yet.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(32)),
                  child: Icon(Icons.mark_email_unread_rounded, size: 64, color: AppTheme.primary),
                ),
                const SizedBox(height: 40),
                Text('Verify Your Email', style: AppTheme.h1),
                const SizedBox(height: 12),
                Text(
                  'Check your inbox for the verification link\nsent to ${authService.currentUser?.email}',
                  textAlign: TextAlign.center,
                  style: AppTheme.body,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : checkStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _isChecking 
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'I Have Verified',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (_isSending || _cooldownSeconds > 0) ? null : resendEmail,
                  child: Text(
                    _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend Email',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () { 
                    authService.signOut();
                    context.go('/register'); 
                  },
                  child: Text(
                    'Back to Register',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
