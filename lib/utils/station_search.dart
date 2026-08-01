import '../models/station.dart';

class CitySearchResult {
  CitySearchResult({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.stationCount,
    this.station,
  });

  final String label;
  final double latitude;
  final double longitude;

  /// Number of stations in this city (only meaningful for city results).
  final int stationCount;

  /// Set only for a single-station result (address-level match).
  final Station? station;
}

const _maxResults = 8;

String _normalize(String input) {
  var result = input.toLowerCase();
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'œ': 'oe',
  };
  for (final entry in accents.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result.trim();
}

/// Match rank: lower is better. Null means no match.
int? _matchRank(String normalizedHaystack, String normalizedQuery) {
  if (normalizedHaystack.startsWith(normalizedQuery)) return 0;
  if (normalizedHaystack.contains(normalizedQuery)) return 1;
  return null;
}

/// Searches the local station dataset for cities and individual station
/// addresses matching [query]. Pure/local — no network involved.
List<CitySearchResult> searchLocations(List<Station> stations, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return const [];

  final cityGroups = <String, List<Station>>{};
  for (final station in stations) {
    if (station.ville.isEmpty) continue;
    cityGroups.putIfAbsent(station.ville, () => []).add(station);
  }

  final cityMatches = <(int rank, CitySearchResult result)>[];
  for (final entry in cityGroups.entries) {
    final rank = _matchRank(_normalize(entry.key), normalizedQuery);
    if (rank == null) continue;

    final group = entry.value;
    final latitude =
        group.map((s) => s.latitude).reduce((a, b) => a + b) / group.length;
    final longitude =
        group.map((s) => s.longitude).reduce((a, b) => a + b) / group.length;

    cityMatches.add((
      rank,
      CitySearchResult(
        label: entry.key,
        latitude: latitude,
        longitude: longitude,
        stationCount: group.length,
      ),
    ));
  }
  cityMatches.sort((a, b) {
    final rankCompare = a.$1.compareTo(b.$1);
    return rankCompare != 0 ? rankCompare : a.$2.label.compareTo(b.$2.label);
  });

  final stationMatches = <(int rank, CitySearchResult result)>[];
  for (final station in stations) {
    if (station.adresse.isEmpty) continue;
    final rank = _matchRank(_normalize(station.adresse), normalizedQuery);
    if (rank == null) continue;

    stationMatches.add((
      rank,
      CitySearchResult(
        label: '${station.adresse}, ${station.ville}',
        latitude: station.latitude,
        longitude: station.longitude,
        stationCount: 1,
        station: station,
      ),
    ));
  }
  stationMatches.sort((a, b) => a.$1.compareTo(b.$1));

  return [
    ...cityMatches.map((e) => e.$2),
    ...stationMatches.map((e) => e.$2),
  ].take(_maxResults).toList();
}
