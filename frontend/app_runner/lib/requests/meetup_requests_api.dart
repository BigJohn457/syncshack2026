import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class MeetupRequestsApi {
  MeetupRequestsApi({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<void> cancel(String requestId) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri('/api/request/post/cancel-request'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'request_id': requestId.trim()}),
      );
    } on Exception {
      throw const AuthException(
        'Could not cancel the request. Check your connection and try again.',
      );
    }

    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the status fallback below for malformed server responses.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Could not cancel the request (${response.statusCode}).',
      );
    }
  }

  Future<Map<String, dynamic>> create({
    required String title,
    required int minPeople,
    required int maxPeople,
    required DateTime meetTime,
    required LatLng location,
    required String placeName,
    required DateTime expiresAt,
  }) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri('/api/request/post/submit-request'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title.trim(),
          'min_people': minPeople,
          'max_people': maxPeople,
          'time': meetTime.toIso8601String(),
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'place_name': placeName.trim(),
          },
          'expired_time': expiresAt.toIso8601String(),
        }),
      );
    } on Exception {
      throw const AuthException(
        'Could not create the meetup. Check your connection and try again.',
      );
    }

    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the status fallback below for malformed server responses.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Could not create the meetup (${response.statusCode}).',
      );
    }
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}
