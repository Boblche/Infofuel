import 'package:flutter/foundation.dart';

import '../models/station.dart';
import '../services/favorites_storage.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesStorage? storage})
      : _storage = storage ?? FavoritesStorage();

  final FavoritesStorage _storage;
  List<Station> _favorites = const [];
  Map<String, String> _customNames = {};

  List<Station> get favorites => _favorites;

  bool isFavorite(String stationId) =>
      _favorites.any((s) => s.id == stationId);

  String? customNameFor(String stationId) => _customNames[stationId];

  /// The nickname the user gave this favorite, or its address/city if none.
  String displayName(Station station) =>
      _customNames[station.id] ??
      (station.adresse.isEmpty ? station.ville : station.adresse);

  Future<void> load() async {
    _favorites = await _storage.load();
    _customNames = await _storage.loadCustomNames();
    notifyListeners();
  }

  Future<void> toggle(Station station) async {
    if (isFavorite(station.id)) {
      _favorites = _favorites.where((s) => s.id != station.id).toList();
      _customNames.remove(station.id);
      await _storage.saveCustomNames(_customNames);
    } else {
      _favorites = [..._favorites, station];
    }
    notifyListeners();
    await _storage.save(_favorites);
  }

  /// Sets or clears (when [name] is null/blank) the nickname for a
  /// favorite station.
  Future<void> setCustomName(String stationId, String? name) async {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _customNames.remove(stationId);
    } else {
      _customNames[stationId] = trimmed;
    }
    notifyListeners();
    await _storage.saveCustomNames(_customNames);
  }
}
