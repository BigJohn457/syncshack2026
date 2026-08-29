import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.address,
    required this.location,
  });

  final String name;
  final String address;
  final LatLng location;
}

class PlaceSearchApi {
  PlaceSearchApi({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey =
          apiKey ??
          const String.fromEnvironment(
            'GEOAPIFY_API_KEY',
            defaultValue: 'ae7b8e6981744f6daa638f8069d0c57d',
          );

  bool get isConfigured => _apiKey.isNotEmpty;

  final http.Client _client;
  final String _apiKey;

  Future<List<PlaceSearchResult>> search(String query, {LatLng? near}) async {
    if (!isConfigured) {
      throw StateError('GEOAPIFY_API_KEY is not configured');
    }
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
      'text': query.trim(),
      'limit': '6',
      'lang': 'en',
      'format': 'json',
      'apiKey': _apiKey,
      if (near != null) 'bias': 'proximity:${near.longitude},${near.latitude}',
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Place search failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['results'] is! List) {
      throw const FormatException('Invalid place search response');
    }

    return (body['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map((result) {
          final longitude = (result['lon'] as num?)?.toDouble();
          final latitude = (result['lat'] as num?)?.toDouble();
          if (latitude == null || longitude == null) return null;

          final name =
              result['name']?.toString() ??
              result['address_line1']?.toString() ??
              result['street']?.toString() ??
              'Selected place';
          final address = result['formatted']?.toString() ?? name;
          return PlaceSearchResult(
            name: name,
            address: address,
            location: LatLng(latitude, longitude),
          );
        })
        .whereType<PlaceSearchResult>()
        .toList();
  }

  void close() => _client.close();
}
