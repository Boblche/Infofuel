import '../utils/fuel_type.dart';

class Station {
  Station({
    required this.id,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    required this.latitude,
    required this.longitude,
    required this.prices,
    required this.isOpen24h,
    required this.services,
    this.distanceMeters,
  });

  final String id;
  final String adresse;
  final String ville;
  final String codePostal;
  final double latitude;
  final double longitude;
  final Map<FuelType, double> prices;
  final bool isOpen24h;
  final List<String> services;

  /// Distance to the user's current position, in meters. Set after fetch.
  final double? distanceMeters;

  double? priceFor(FuelType fuel) => prices[fuel];

  FuelType? get cheapestFuel {
    if (prices.isEmpty) return null;
    return prices.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  double? get cheapestPrice {
    if (prices.isEmpty) return null;
    return prices.values.reduce((a, b) => a <= b ? a : b);
  }

  Station copyWith({double? distanceMeters}) {
    return Station(
      id: id,
      adresse: adresse,
      ville: ville,
      codePostal: codePostal,
      latitude: latitude,
      longitude: longitude,
      prices: prices,
      isOpen24h: isOpen24h,
      services: services,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    final geom = json['geom'] as Map<String, dynamic>?;
    final lat = (geom?['lat'] as num?)?.toDouble() ??
        double.tryParse('${json['latitude']}') ??
        0;
    final lon = (geom?['lon'] as num?)?.toDouble() ??
        double.tryParse('${json['longitude']}') ??
        0;

    final prices = <FuelType, double>{};
    for (final fuel in FuelType.values) {
      final raw = json[fuel.priceField];
      if (raw is num) {
        prices[fuel] = raw.toDouble();
      } else if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) prices[fuel] = parsed;
      }
    }

    return Station(
      id: '${json['id']}',
      adresse: (json['adresse'] as String?)?.trim() ?? '',
      ville: (json['ville'] as String?)?.trim() ?? '',
      codePostal: '${json['cp'] ?? ''}',
      latitude: lat,
      longitude: lon,
      prices: prices,
      isOpen24h: json['horaires_automate_24_24'] == 'Oui',
      services: (json['services_service'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adresse': adresse,
      'ville': ville,
      'cp': codePostal,
      'latitude': latitude,
      'longitude': longitude,
      'prices': prices.map((fuel, price) => MapEntry(fuel.apiKey, price)),
      'isOpen24h': isOpen24h,
      'services': services,
    };
  }

  factory Station.fromStoredJson(Map<String, dynamic> json) {
    final storedPrices = json['prices'] as Map<String, dynamic>? ?? const {};
    final prices = <FuelType, double>{};
    for (final fuel in FuelType.values) {
      final raw = storedPrices[fuel.apiKey];
      if (raw is num) prices[fuel] = raw.toDouble();
    }

    return Station(
      id: '${json['id']}',
      adresse: json['adresse'] as String? ?? '',
      ville: json['ville'] as String? ?? '',
      codePostal: json['cp'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      prices: prices,
      isOpen24h: json['isOpen24h'] as bool? ?? false,
      services:
          (json['services'] as List<dynamic>?)?.map((e) => '$e').toList() ??
              const [],
    );
  }
}
