import 'package:flutter_test/flutter_test.dart';
import 'package:infofuel/models/station.dart';
import 'package:infofuel/utils/station_search.dart';

Station _station(String id, String adresse, String ville, double lat, double lon) {
  return Station(
    id: id,
    adresse: adresse,
    ville: ville,
    codePostal: '00000',
    latitude: lat,
    longitude: lon,
    prices: const {},
    isOpen24h: false,
    services: const [],
  );
}

void main() {
  group('searchLocations', () {
    final stations = [
      _station('1', '1 Avenue du Général Sarrail', 'Paris', 48.86, 2.25),
      _station('2', '10 Rue de la Paix', 'Paris', 48.87, 2.27),
      _station('3', '2 Avenue Gabriel Péri', 'Argenteuil', 48.95, 2.25),
      _station('4', '5 Rue Victor Hugo', 'Orléans', 47.9, 1.9),
    ];

    test('returns nothing for an empty query', () {
      expect(searchLocations(stations, ''), isEmpty);
    });

    test('matches a city by prefix and returns its centroid', () {
      final results = searchLocations(stations, 'Par');

      final city = results.firstWhere((r) => r.station == null);
      expect(city.label, 'Paris');
      expect(city.stationCount, 2);
      expect(city.latitude, closeTo(48.865, 0.001));
      expect(city.longitude, closeTo(2.26, 0.001));
    });

    test('matches a city name written without accents', () {
      final results = searchLocations(stations, 'orleans');

      expect(results.any((r) => r.label == 'Orléans'), isTrue);
    });

    test('matches an individual station by address', () {
      final results = searchLocations(stations, 'Gabriel Péri');

      final match = results.firstWhere((r) => r.station != null);
      expect(match.station!.id, '3');
    });

    test('ranks prefix matches above substring matches', () {
      final results = searchLocations(stations, 'aris');

      // "Paris" only contains "aris" (not a prefix), should still be found.
      expect(results.any((r) => r.label == 'Paris'), isTrue);
    });
  });
}
