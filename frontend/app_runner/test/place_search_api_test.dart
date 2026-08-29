import 'dart:convert';

import 'package:app_runner/requests/place_search_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('parses Geoapify autocomplete results and adds location bias', () async {
    late Uri requestedUri;
    final api = PlaceSearchApi(
      apiKey: 'test-key',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Sydney Opera House',
                'formatted': 'Sydney Opera House, Sydney NSW 2000, Australia',
                'lat': -33.857198,
                'lon': 151.2151234,
              },
            ],
          }),
          200,
        );
      }),
    );

    final results = await api.search(
      'Sydney Opera',
      near: const LatLng(-33.8688, 151.2093),
    );

    expect(requestedUri.host, 'api.geoapify.com');
    expect(requestedUri.path, '/v1/geocode/autocomplete');
    expect(requestedUri.queryParameters['apiKey'], 'test-key');
    expect(requestedUri.queryParameters['bias'], 'proximity:151.2093,-33.8688');
    expect(results.single.name, 'Sydney Opera House');
    expect(results.single.location.latitude, -33.857198);
    expect(results.single.location.longitude, 151.2151234);
  });
}
