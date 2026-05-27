import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:localmart/services/user_service.dart';

class LocationService {
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
      final city = address['city'] ?? address['town'] ?? address['county'] ?? '';
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

  static Future<void> requestAndUpdateLocation(String uid) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    try {
      Position position = await Geolocator.getCurrentPosition();
      await reverseGeocode(uid, position.latitude, position.longitude);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
