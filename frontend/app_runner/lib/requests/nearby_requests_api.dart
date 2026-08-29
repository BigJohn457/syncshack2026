import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class NearbyRequest {
  const NearbyRequest({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.location,
    required this.placeName,
    required this.minPeople,
    required this.maxPeople,
    required this.meetTime,
    required this.expiresAt,
    required this.meetupId,
  });

  final String id;
  final String creatorId;
  final String title;
  final LatLng location;
  final String placeName;
  final int minPeople;
  final int maxPeople;
  final DateTime? meetTime;
  final DateTime? expiresAt;
  final String? meetupId;

  factory NearbyRequest.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map<String, dynamic>) {
      throw const FormatException('Request location is missing');
    }
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const FormatException('Request coordinates are missing');
    }

    return NearbyRequest(
      id: json['request_id']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Meetup request',
      location: LatLng(latitude, longitude),
      placeName: location['place_name']?.toString() ?? 'Nearby',
      minPeople: (json['min_people'] as num?)?.toInt() ?? 1,
      maxPeople: (json['max_people'] as num?)?.toInt() ?? 1,
      meetTime: DateTime.tryParse(json['time']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expired_time']?.toString() ?? ''),
      meetupId: json['meetup_id']?.toString(),
    );
  }
}

class NearbyRequestsApi {
  NearbyRequestsApi({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<List<NearbyRequest>> fetch({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final uri = ApiConfig.uri('/api/request/get/all-request').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radiusKm.toStringAsFixed(2),
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri);
    } on Exception {
      throw const AuthException(
        'Could not load nearby requests. Check your connection.',
      );
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      payload = decoded;
    } on FormatException {
      throw const AuthException('The server returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Could not load requests (${response.statusCode}).',
      );
    }

    final data = payload['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NearbyRequest.fromJson)
        .where((request) => request.id.isNotEmpty)
        .toList();
  }
}
