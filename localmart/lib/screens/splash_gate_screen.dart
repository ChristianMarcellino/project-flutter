import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/services/auth_service.dart';

class SplashGateScreen extends StatefulWidget {
  const SplashGateScreen({super.key});

  @override
  State<SplashGateScreen> createState() => _SplashGateScreenState();
}

class _SplashGateScreenState extends State<SplashGateScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final gpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      await Geolocator.openLocationSettings();
    }

    final user = authService.currentUser;

    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (!user.emailVerified) {
      context.go('/verify-email');
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
