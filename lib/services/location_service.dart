import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  LocationServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationServiceException(
        'La localisation est désactivée. Activez-la dans les réglages de '
        'votre téléphone pour trouver les stations autour de vous.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationServiceException(
        'La permission de localisation est nécessaire pour trouver les '
        'stations autour de vous.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'La permission de localisation a été refusée définitivement. '
        'Autorisez-la dans les réglages de l\'application.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw LocationServiceException(
        'Impossible d\'obtenir votre position (signal GPS trop faible). '
        'Réessayez dans un endroit dégagé.',
      );
    }
  }

  double distanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
