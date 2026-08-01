import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/station.dart';

class FuelPriceApiException implements Exception {
  FuelPriceApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Client for the French government's open "Prix des carburants" dataset.
/// https://data.economie.gouv.fr — no API key required.
class FuelPriceApi {
  static const _exportUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/'
      'prix-des-carburants-en-france-flux-instantane-v2/exports/json';

  /// Fetches every station in France in a single request (the dataset is
  /// refreshed by the government roughly once a day, so there is no need to
  /// query it more granularly).
  Future<List<Station>> fetchAllStations() async {
    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(_exportUrl))
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw FuelPriceApiException(
        'Impossible de contacter le service des prix des carburants. '
        'Vérifiez votre connexion internet.',
      );
    }

    if (response.statusCode != 200) {
      throw FuelPriceApiException(
        'Le service des prix des carburants a répondu avec une erreur '
        '(${response.statusCode}).',
      );
    }

    final results = jsonDecode(utf8.decode(response.bodyBytes));
    return (results as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Station.fromJson)
        .toList();
  }
}
