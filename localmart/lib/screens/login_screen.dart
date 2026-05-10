import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/widgets/auth_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorText = '';
  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Email and password are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      final userCredential = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await user.reload();

        if (!user.emailVerified) {
          if (mounted) {
            context.go('/verify-email');
          }
          return;
        }
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorText)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    try {
      await authService.resetPassword(email: _emailController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reset password failed: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    size: 55,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Login to continue using LocalMart',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              AuthInputField(
                label: 'Email',
                hint: 'your@email.com',
                icon: Icons.mail_outline,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              AuthInputField(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                isPassword: true,
                obscurePassword: _obscurePassword,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if(_emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your email address.'),
                        ),
                      );
                      return;
                    }
                    _resetPassword();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent successfully.'),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authService.signInWithGoogle();
                  },
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 32,
                    color: Color(0xFF111827),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/register');
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Color(0xFF6B7280)),
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
