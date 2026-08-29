import 'dart:convert';

import 'package:app_runner/requests/meetup_requests_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('cancels a request using the documented API payload', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'request_id': 'request-1', 'status': 'cancelled'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await MeetupRequestsApi(client: client).cancel('request-1');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/request/post/cancel-request');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(jsonDecode(captured.body), {'request_id': 'request-1'});
  });

  test('creates a meetup using the documented API payload', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'request_id': 'request-1'},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = MeetupRequestsApi(client: client);
    final meetTime = DateTime(2026, 8, 29, 13);

    final result = await api.create(
      title: 'Lunch at Broadway',
      minPeople: 2,
      maxPeople: 4,
      meetTime: meetTime,
      location: const LatLng(-33.8832, 151.1943),
      placeName: 'Broadway',
      expiresAt: meetTime.add(const Duration(minutes: 30)),
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/request/post/submit-request');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(jsonDecode(captured.body), {
      'title': 'Lunch at Broadway',
      'min_people': 2,
      'max_people': 4,
      'time': '2026-08-29T13:00:00.000',
      'location': {
        'latitude': -33.8832,
        'longitude': 151.1943,
        'place_name': 'Broadway',
      },
      'expired_time': '2026-08-29T13:30:00.000',
    });
    expect(result['request_id'], 'request-1');
  });
}
