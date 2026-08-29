import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class MeetupRequestStatus {
  const MeetupRequestStatus({
    required this.requestId,
    required this.meetupId,
    required this.requestStatus,
    required this.meetupStatus,
    required this.acceptedCount,
    required this.maxPeople,
  });

  final String requestId;
  final String? meetupId;
  final String requestStatus;
  final String? meetupStatus;
  final int acceptedCount;
  final int maxPeople;

  factory MeetupRequestStatus.fromJson(Map<String, dynamic> json) {
    return MeetupRequestStatus(
      requestId: json['request_id']?.toString() ?? '',
      meetupId: json['meetup_id']?.toString(),
      requestStatus: json['request_status']?.toString() ?? '',
      meetupStatus: json['meetup_status']?.toString(),
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      maxPeople: (json['max_people'] as num?)?.toInt() ?? 1,
    );
  }
}

class JoinedMeetupRequest {
  const JoinedMeetupRequest({
    required this.requestId,
    required this.meetupId,
    required this.invitationStatus,
  });

  final String requestId;
  final String meetupId;
  final String invitationStatus;
}

class MeetupRequestsApi {
  MeetupRequestsApi({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<JoinedMeetupRequest> join(String requestId) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri('/api/request/post/join-request'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'request_id': requestId.trim()}),
      );
    } on Exception {
      throw const AuthException(
        'Could not join the meetup. Check your internet connection.',
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
            'Could not join the meetup (${response.statusCode}).',
      );
    }
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid meetup.');
    }
    final meetupId = data['meetup_id']?.toString() ?? '';
    if (meetupId.isEmpty) {
      throw const AuthException('The server did not return a meetup ID.');
    }
    return JoinedMeetupRequest(
      requestId: data['request_id']?.toString() ?? requestId,
      meetupId: meetupId,
      invitationStatus: data['invitation_status']?.toString() ?? 'pending',
    );
  }

  Future<MeetupRequestStatus> status(String requestId) async {
    http.Response response;
    try {
      final uri = ApiConfig.uri(
        '/api/home/get/request-status',
      ).replace(queryParameters: {'request_id': requestId.trim()});
      response = await _client.get(uri);
    } on Exception {
      throw const AuthException('Could not refresh the request status.');
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
            'Could not refresh the request (${response.statusCode}).',
      );
    }
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException(
        'The server returned an invalid request status.',
      );
    }
    return MeetupRequestStatus.fromJson(data);
  }

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
