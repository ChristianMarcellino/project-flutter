import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/widgets/auth_input_field.dart';
import 'package:localmart/widgets/custom_button.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
      );

      _updateLocation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent! Check your inbox."),
          ),
        );
        context.go('/verify-email');
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

  Future<void> _updateLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      await reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> reverseGeocode(double lat, double lng) async {
    try {
      final user = authService.currentUser;

      if (user == null) return;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'localmart-app'},
      );

      final data = jsonDecode(response.body);

      final address = data['address'] ?? {};

      final city =
          address['city'] ?? address['town'] ?? address['county'] ?? '';

      final district = address['suburb'] ?? address['city_district'] ?? '';

      final province = address['state'] ?? '';

      final locationName = [
        district,
        city,
      ].where((e) => e.isNotEmpty).join(', ');

      await UserService.updateLocation(
        user.uid,
        lat,
        lng,
        locationName: locationName,
        city: city,
        district: district,
        province: province,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(child: Text('Create Account', style: AppTheme.h1)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Join our community today',
                      style: AppTheme.body,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AuthInputField(
                    label: 'Username',
                    hint: 'johndoe',
                    icon: Icons.person_outline_rounded,
                    controller: _usernameController,
                  ),
                  AuthInputField(
                    label: 'Email',
                    hint: 'your@email.com',
                    icon: Icons.alternate_email_rounded,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  AuthInputField(
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    isPassword: true,
                    obscurePassword: _obscurePassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  AuthInputField(
                    label: 'Phone Number',
                    hint: '8123456789',
                    icon: Icons.phone_android_rounded,
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    onPressed: register,
                    text: 'Register Now',
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: AppTheme.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
