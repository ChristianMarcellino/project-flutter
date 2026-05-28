import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsDisabledScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const GpsDisabledScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80),
              const SizedBox(height: 16),
              const Text(
                "GPS is required to use LocalMart",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  onRetry();
                },
                child: const Text("Enable GPS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
