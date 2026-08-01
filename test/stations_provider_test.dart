import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:infofuel/models/station.dart';
import 'package:infofuel/state/stations_provider.dart';
import 'package:infofuel/utils/fuel_type.dart';

Position _positionAt(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Station _stationAt(String id, double lat, double lon,
    {Map<FuelType, double> prices = const {}, double? distanceMeters}) {
  return Station(
    id: id,
    adresse: 'Adresse $id',
    ville: 'Ville',
    codePostal: '00000',
    latitude: lat,
    longitude: lon,
    prices: prices,
    isOpen24h: false,
    services: const [],
    distanceMeters: distanceMeters,
  );
}

void main() {
  group('StationsProvider.sortByDistance', () {
    test('orders stations from nearest to farthest', () {
      final provider = StationsProvider();
      final from = _positionAt(48.8566, 2.3522); // Paris

      final near = _stationAt('near', 48.86, 2.35);
      final far = _stationAt('far', 45.75, 4.85); // Lyon, far from Paris
      final mid = _stationAt('mid', 48.9, 2.4);

      final sorted = provider.sortByDistance([far, near, mid], from);

      expect(sorted.map((s) => s.id).toList(), ['near', 'mid', 'far']);
      expect(sorted.first.distanceMeters, isNotNull);
      expect(sorted.first.distanceMeters! < sorted.last.distanceMeters!, isTrue);
    });
  });

  group('StationsProvider.applyFilterAndSort', () {
    final withGazole =
        _stationAt('a', 48.86, 2.35, prices: {FuelType.gazole: 1.9});
    final cheaperGazole =
        _stationAt('b', 48.87, 2.36, prices: {FuelType.gazole: 1.7});
    final noGazole = _stationAt('c', 48.85, 2.34, prices: {FuelType.sp95: 1.8});
    final all = [withGazole, cheaperGazole, noGazole];

    test('keeps every station when no fuel filter is selected', () {
      final result = StationsProvider.applyFilterAndSort(
        all,
        fuel: null,
        sort: StationSort.distance,
      );
      expect(result.length, 3);
    });

    test('drops stations missing the selected fuel', () {
      final result = StationsProvider.applyFilterAndSort(
        all,
        fuel: FuelType.gazole,
        sort: StationSort.distance,
      );
      expect(result.map((s) => s.id).toSet(), {'a', 'b'});
    });

    test('sorts by cheapest price when requested', () {
      final result = StationsProvider.applyFilterAndSort(
        all,
        fuel: FuelType.gazole,
        sort: StationSort.price,
      );
      expect(result.map((s) => s.id).toList(), ['b', 'a']);
    });

    test('sorts by each station\'s cheapest fuel when no fuel is selected', () {
      final result = StationsProvider.applyFilterAndSort(
        all,
        fuel: null,
        sort: StationSort.price,
      );
      // a: 1.9 (gazole), b: 1.7 (gazole), c: 1.8 (sp95)
      expect(result.map((s) => s.id).toList(), ['b', 'c', 'a']);
    });

    test('drops stations beyond the selected max distance', () {
      final near = _stationAt('near', 48.86, 2.35, distanceMeters: 2000);
      final far = _stationAt('far', 48.9, 2.4, distanceMeters: 15000);
      final unknown = _stationAt('unknown', 48.87, 2.36);

      final result = StationsProvider.applyFilterAndSort(
        [near, far, unknown],
        fuel: null,
        sort: StationSort.distance,
        maxDistanceKm: 5,
      );

      expect(result.map((s) => s.id).toList(), ['near']);
    });
  });

  group('StationsProvider.filterInBounds', () {
    test('keeps only stations within the given rectangle', () {
      final inside = _stationAt('inside', 48.86, 2.35);
      final outsideNorth = _stationAt('outside-north', 49.5, 2.35);
      final outsideEast = _stationAt('outside-east', 48.86, 4.0);

      final result = StationsProvider.filterInBounds(
        [inside, outsideNorth, outsideEast],
        south: 48.8,
        west: 2.2,
        north: 48.9,
        east: 2.5,
      );

      expect(result.map((s) => s.id).toList(), ['inside']);
    });
  });
}
