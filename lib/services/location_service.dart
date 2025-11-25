import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<Placemark?> getPlacemark(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'tr_TR',
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
    } catch (_) {}
    return null;
  }

  static double distanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(
          startLat,
          startLng,
          endLat,
          endLng,
        ) /
        1000;
  }
}


