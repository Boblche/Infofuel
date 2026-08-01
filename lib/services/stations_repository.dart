import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/station.dart';
import 'fuel_price_api.dart';

class StationsSnapshot {
  StationsSnapshot({required this.stations, required this.fetchedAt});

  final List<Station> stations;
  final DateTime fetchedAt;
}

/// Caches the full French fuel-price dataset on disk. The government only
/// refreshes it roughly once a day, so a single network fetch is reused for
/// [maxAge] before the next one is required.
class StationsRepository {
  StationsRepository({
    FuelPriceApi? api,
    Duration maxAge = const Duration(hours: 24),
  })  : _api = api ?? FuelPriceApi(),
        _maxAge = maxAge;

  final FuelPriceApi _api;
  final Duration _maxAge;

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/stations_cache.json');
  }

  Future<StationsSnapshot> load({bool forceRefresh = false}) async {
    final file = await _cacheFile();

    if (!forceRefresh) {
      final cached = await _readCache(file);
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _maxAge) {
        return cached;
      }
    }

    try {
      final stations = await _api.fetchAllStations();
      final snapshot = StationsSnapshot(
        stations: stations,
        fetchedAt: DateTime.now(),
      );
      await _writeCache(file, snapshot);
      return snapshot;
    } catch (e) {
      final cached = await _readCache(file);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<StationsSnapshot?> _readCache(File file) async {
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final fetchedAt = DateTime.parse(decoded['fetchedAt'] as String);
      final stations = (decoded['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Station.fromStoredJson)
          .toList();
      return StationsSnapshot(stations: stations, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(File file, StationsSnapshot snapshot) async {
    final encoded = jsonEncode({
      'fetchedAt': snapshot.fetchedAt.toIso8601String(),
      'stations': snapshot.stations.map((s) => s.toJson()).toList(),
    });
    await file.writeAsString(encoded);
  }
}
