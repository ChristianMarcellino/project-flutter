import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:localmart/services/user_service.dart';

enum LocationAccessResult { success, gpsDisabled, denied, deniedForever }

class LocationService {
  static Future<LocationAccessResult> ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return LocationAccessResult.gpsDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationAccessResult.denied;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationAccessResult.deniedForever;
    }

    return LocationAccessResult.success;
  }

  static Future<void> reverseGeocode(String uid, double lat, double lng) async {
    try {
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
        uid,
        lat,
        lng,
        locationName: locationName,
        city: city,
        district: district,
        province: province,
      );
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  static Future<bool> ensureAndUpdateLocation(String uid) async {
    final access = await ensureLocationAccess();

    if (access != LocationAccessResult.success) {
      return false;
    }

    return await updateUserLocation(uid);
  }

  static Future<bool> updateUserLocation(String uid) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await reverseGeocode(uid, position.latitude, position.longitude);

      return true;
    } catch (e) {
      debugPrint('Location update error: $e');
      return false;
    }
  }
}
