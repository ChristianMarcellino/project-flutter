import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    setState(() {
      _cooldownSeconds = 60;
    });

    while (_cooldownSeconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _cooldownSeconds--;
      });
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await user.sendEmailVerification();
      startCooldown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent successfully. Please check your inbox.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Failed to resend verification email.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isChecking = true;
    });

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }

    if (refreshedUser != null && refreshedUser.emailVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
          ),
        );

        context.go('/');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your email is not verified yet. Please check your inbox.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 60,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'We have sent a verification link to:\n$userEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please check your inbox (and spam folder) before continuing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : checkVerificationStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isChecking
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'I Have Verified',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: (_isSending || _cooldownSeconds > 0)
                        ? null
                        : resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator()
                        : Text(
                            _cooldownSeconds > 0
                                ? 'Resend in ${_cooldownSeconds}s'
                                : 'Resend Verification Email',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (mounted) {
                      context.go('/register');
                    }
                  },
                  child: const Text(
                    'Back to Register',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
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
