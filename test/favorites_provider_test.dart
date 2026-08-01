import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:infofuel/models/station.dart';
import 'package:infofuel/state/favorites_provider.dart';
import 'package:infofuel/utils/fuel_type.dart';

Station _stationAt(String id) {
  return Station(
    id: id,
    adresse: 'Adresse $id',
    ville: 'Ville',
    codePostal: '00000',
    latitude: 0,
    longitude: 0,
    prices: const {FuelType.gazole: 1.9},
    isOpen24h: false,
    services: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesProvider custom names', () {
    test('displayName falls back to the address when no nickname is set', () {
      final provider = FavoritesProvider();
      final station = _stationAt('a');
      expect(provider.displayName(station), 'Adresse a');
    });

    test('setCustomName overrides displayName', () async {
      final provider = FavoritesProvider();
      final station = _stationAt('a');

      await provider.setCustomName(station.id, 'Mon Total du travail');

      expect(provider.customNameFor(station.id), 'Mon Total du travail');
      expect(provider.displayName(station), 'Mon Total du travail');
    });

    test('setCustomName with a blank value clears the nickname', () async {
      final provider = FavoritesProvider();
      final station = _stationAt('a');

      await provider.setCustomName(station.id, 'Nickname');
      await provider.setCustomName(station.id, '   ');

      expect(provider.customNameFor(station.id), isNull);
      expect(provider.displayName(station), 'Adresse a');
    });

    test('removing a station from favorites clears its nickname', () async {
      final provider = FavoritesProvider();
      final station = _stationAt('a');

      await provider.toggle(station);
      await provider.setCustomName(station.id, 'Nickname');
      expect(provider.customNameFor(station.id), 'Nickname');

      await provider.toggle(station);

      expect(provider.isFavorite(station.id), isFalse);
      expect(provider.customNameFor(station.id), isNull);
    });
  });
}
