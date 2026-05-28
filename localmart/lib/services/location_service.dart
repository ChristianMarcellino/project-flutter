import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:localmart/services/user_service.dart';

class LocationService {
  static Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
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
      debugPrint(e.toString());
    }
  }

  static Future<bool> requestAndUpdateLocationTemp() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestAndUpdateLocation(String uid) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await reverseGeocode(uid, position.latitude, position.longitude);

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
