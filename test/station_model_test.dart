import 'package:flutter_test/flutter_test.dart';
import 'package:infofuel/models/station.dart';
import 'package:infofuel/utils/fuel_type.dart';

void main() {
  group('Station.fromJson', () {
    test('parses a real API record', () {
      final json = {
        'id': 80570001,
        'adresse': 'Rue Joliot Curie',
        'ville': 'Dargnies',
        'cp': '80570',
        'geom': {'lon': 1.52562, 'lat': 50.04475},
        'gazole_prix': 2.185,
        'sp95_prix': 2.065,
        'sp98_prix': 2.109,
        'e10_prix': null,
        'e85_prix': null,
        'gplc_prix': null,
        'carburants_disponibles': ['Gazole', 'SP95', 'SP98'],
        'horaires_automate_24_24': 'Non',
        'services_service': ['Boutique alimentaire'],
        'departement': 'Somme',
      };

      final station = Station.fromJson(json);

      expect(station.id, '80570001');
      expect(station.adresse, 'Rue Joliot Curie');
      expect(station.ville, 'Dargnies');
      expect(station.latitude, 50.04475);
      expect(station.longitude, 1.52562);
      expect(station.prices[FuelType.gazole], 2.185);
      expect(station.prices[FuelType.sp95], 2.065);
      expect(station.prices.containsKey(FuelType.e10), isFalse);
      expect(station.isOpen24h, isFalse);
      expect(station.services, ['Boutique alimentaire']);
      expect(station.cheapestFuel, FuelType.sp95);
    });

    test('round-trips through toJson/fromStoredJson for favorites', () {
      final original = Station.fromJson({
        'id': 1,
        'adresse': 'Rue Test',
        'ville': 'Testville',
        'cp': '75000',
        'geom': {'lon': 2.0, 'lat': 48.0},
        'gazole_prix': 1.9,
        'horaires_automate_24_24': 'Oui',
        'services_service': ['Bar'],
        'departement': 'Paris',
      });

      final restored = Station.fromStoredJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.adresse, original.adresse);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.prices[FuelType.gazole], 1.9);
      expect(restored.isOpen24h, isTrue);
    });
  });
}
