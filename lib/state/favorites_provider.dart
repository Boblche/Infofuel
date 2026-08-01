import 'package:flutter/foundation.dart';

import '../models/station.dart';
import '../services/favorites_storage.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesStorage? storage})
      : _storage = storage ?? FavoritesStorage();

  final FavoritesStorage _storage;
  List<Station> _favorites = const [];

  List<Station> get favorites => _favorites;

  bool isFavorite(String stationId) =>
      _favorites.any((s) => s.id == stationId);

  Future<void> load() async {
    _favorites = await _storage.load();
    notifyListeners();
  }

  Future<void> toggle(Station station) async {
    if (isFavorite(station.id)) {
      _favorites = _favorites.where((s) => s.id != station.id).toList();
    } else {
      _favorites = [..._favorites, station];
    }
    notifyListeners();
    await _storage.save(_favorites);
  }
}
