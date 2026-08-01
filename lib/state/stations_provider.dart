import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/station.dart';
import '../services/location_service.dart';
import '../services/stations_repository.dart';
import '../utils/fuel_type.dart';

enum StationsStatus { idle, loading, loaded, error }

enum StationSort { distance, price }

class StationsProvider extends ChangeNotifier {
  StationsProvider({
    StationsRepository? repository,
    LocationService? locationService,
  })  : _repository = repository ?? StationsRepository(),
        _locationService = locationService ?? LocationService();

  /// How many of the nearest stations are shown/considered on the Liste
  /// screen. The full dataset (~9800 stations nationwide) is kept in
  /// [_allStations]; this only bounds what's displayed as "near you".
  static const _nearbyStationsLimit = 100;

  final StationsRepository _repository;
  final LocationService _locationService;

  StationsStatus status = StationsStatus.idle;
  String? errorMessage;
  DateTime? lastUpdated;

  Position? userPosition;
  List<Station> _allStations = const [];

  /// The full nationwide dataset, e.g. for searching by city/address.
  List<Station> get allStations => _allStations;

  FuelType? selectedFuel;
  StationSort sort = StationSort.distance;

  /// Max distance from the user, in km, for the Liste screen. `null` means
  /// no limit.
  double? maxDistanceKm;

  /// Station the Carte screen should center on next, e.g. after tapping
  /// "Voir sur la carte" from a detail sheet. Consumed once, then cleared.
  Station? focusStation;

  void focusOnMap(Station station) {
    focusStation = station;
    notifyListeners();
  }

  void clearMapFocus() {
    focusStation = null;
  }

  Future<void> initialize() => _load(forceRefresh: false);

  Future<void> refresh() => _load(forceRefresh: true);

  Future<void> _load({required bool forceRefresh}) async {
    status = StationsStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      userPosition = position;

      final snapshot = await _repository.load(forceRefresh: forceRefresh);
      _allStations = sortByDistance(snapshot.stations, position);
      lastUpdated = snapshot.fetchedAt;
      status = StationsStatus.loaded;
    } catch (e) {
      errorMessage = e.toString();
      status = StationsStatus.error;
    }
    notifyListeners();
  }

  @visibleForTesting
  List<Station> sortByDistance(List<Station> stations, Position from) {
    final withDistance = stations
        .map((s) => s.copyWith(
              distanceMeters: _locationService.distanceMeters(
                startLatitude: from.latitude,
                startLongitude: from.longitude,
                endLatitude: s.latitude,
                endLongitude: s.longitude,
              ),
            ))
        .toList();
    withDistance.sort(
      (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
    );
    return withDistance;
  }

  void setFuelFilter(FuelType? fuel) {
    selectedFuel = fuel;
    notifyListeners();
  }

  void setSort(StationSort newSort) {
    sort = newSort;
    notifyListeners();
  }

  void setMaxDistance(double? km) {
    maxDistanceKm = km;
    notifyListeners();
  }

  /// Stations near the user, sorted/filtered for the Liste screen.
  List<Station> get stations {
    final nearest = _allStations.take(_nearbyStationsLimit).toList();
    return applyFilterAndSort(
      nearest,
      fuel: selectedFuel,
      sort: sort,
      maxDistanceKm: maxDistanceKm,
    );
  }

  /// Stations within a rectangular map viewport — purely local filtering
  /// over the already-cached dataset, no network call.
  List<Station> stationsInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    final inBounds = filterInBounds(
      _allStations,
      south: south,
      west: west,
      north: north,
      east: east,
    );
    return applyFilterAndSort(inBounds, fuel: selectedFuel, sort: sort);
  }

  @visibleForTesting
  static List<Station> filterInBounds(
    List<Station> stations, {
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    return stations
        .where((s) =>
            s.latitude >= south &&
            s.latitude <= north &&
            s.longitude >= west &&
            s.longitude <= east)
        .toList();
  }

  @visibleForTesting
  static List<Station> applyFilterAndSort(
    List<Station> stations, {
    required FuelType? fuel,
    required StationSort sort,
    double? maxDistanceKm,
  }) {
    var result = stations;

    if (fuel != null) {
      result = result.where((s) => s.priceFor(fuel) != null).toList();
    }

    if (maxDistanceKm != null) {
      final maxMeters = maxDistanceKm * 1000;
      result = result.where((s) => (s.distanceMeters ?? double.infinity) <= maxMeters).toList();
    }

    if (sort == StationSort.price) {
      // With a fuel selected, stations missing it were already dropped
      // above, so priceFor(fuel) is never null there. Without one, fall
      // back to each station's cheapest price across all its fuels.
      double? priceOf(Station s) => fuel != null ? s.priceFor(fuel) : s.cheapestPrice;
      result = [...result]
        ..sort((a, b) {
          final priceA = priceOf(a);
          final priceB = priceOf(b);
          if (priceA == null) return priceB == null ? 0 : 1;
          if (priceB == null) return -1;
          return priceA.compareTo(priceB);
        });
    }

    return result;
  }
}
