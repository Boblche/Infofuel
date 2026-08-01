import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';

class FavoritesStorage {
  static const _prefsKey = 'favorite_stations_v1';

  Future<List<Station>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Station.fromStoredJson)
        .toList();
  }

  Future<void> save(List<Station> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
