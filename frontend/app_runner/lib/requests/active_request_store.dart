import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

enum UserMeetupStage { requesting, chat, meetup, rating }

class ActiveMeetupRequest {
  const ActiveMeetupRequest({
    required this.id,
    required this.activity,
    required this.people,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.expiresAt,
    this.acceptedCount = 0,
    this.meetupId = '',
    this.stage = UserMeetupStage.requesting,
  });

  final String id;
  final String activity;
  final String people;
  final String place;
  final String time;
  final double latitude;
  final double longitude;
  final DateTime expiresAt;
  final int acceptedCount;
  final String meetupId;
  final UserMeetupStage stage;

  int get maximumPeople => int.tryParse(people.split('-').last.trim()) ?? 1;
  bool get hasMatch => acceptedCount > 0 && meetupId.isNotEmpty;
  bool get isFull => hasMatch && acceptedCount >= maximumPeople;

  ActiveMeetupRequest withStatus({
    required int acceptedCount,
    required String meetupId,
  }) => ActiveMeetupRequest(
    id: id,
    activity: activity,
    people: people,
    place: place,
    time: time,
    latitude: latitude,
    longitude: longitude,
    expiresAt: expiresAt,
    acceptedCount: acceptedCount,
    meetupId: meetupId,
    stage: stage,
  );

  factory ActiveMeetupRequest.fromJson(Map<String, dynamic> json) {
    final stageName = json['stage']?.toString() ?? 'requesting';
    return ActiveMeetupRequest(
      id: json['request_id']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      people: '${json['min_people'] ?? 1}-${json['max_people'] ?? 1}',
      place: json['place']?.toString() ?? '',
      time: json['meet_time']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -33.8688,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 151.2093,
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now(),
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      meetupId: json['meetup_id']?.toString() ?? '',
      stage: UserMeetupStage.values.firstWhere(
        (value) => value.name == stageName,
        orElse: () => UserMeetupStage.requesting,
      ),
    );
  }
}

/// Existing callers use this facade, but state now always comes from the API.
/// No request or stage data is persisted on the device.
class ActiveRequestStore {
  const ActiveRequestStore._();

  static Future<ActiveMeetupRequest?> load({http.Client? client}) async {
    final apiClient = client ?? createHttpClient();
    try {
      final response = await apiClient.get(
        ApiConfig.uri('/api/home/get/current-stage'),
      );
      Map<String, dynamic> payload = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } on FormatException {
        // The status fallback below reports malformed responses.
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          payload['error']?.toString() ??
              'Could not restore your current meetup stage.',
        );
      }
      final data = payload['data'];
      return data is Map<String, dynamic>
          ? ActiveMeetupRequest.fromJson(data)
          : null;
    } on AuthException {
      rethrow;
    } on Exception {
      throw const AuthException(
        'Could not restore your current meetup stage. Check your connection.',
      );
    } finally {
      if (client == null) apiClient.close();
    }
  }

  static Future<void> save(ActiveMeetupRequest request) async {}
  static Future<void> clear() async {}
}
