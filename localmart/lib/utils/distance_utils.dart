import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  static String formatDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    if (startLatitude == 0 || startLongitude == 0) {
      return 'Unknown distance';
    }
    final distanceMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    final distanceKm = distanceMeters / 1000;
    if (distanceKm < 1) {
      return '${distanceMeters.round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }
}
