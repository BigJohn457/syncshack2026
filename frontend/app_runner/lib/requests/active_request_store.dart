import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  int get maximumPeople {
    final parts = people.split('-');
    return int.tryParse(parts.last.trim()) ?? 1;
  }

  bool get hasMatch => acceptedCount > 0 && meetupId.isNotEmpty;
  bool get isFull => hasMatch && acceptedCount >= maximumPeople;

  ActiveMeetupRequest withStatus({
    required int acceptedCount,
    required String meetupId,
  }) {
    return ActiveMeetupRequest(
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'activity': activity,
    'people': people,
    'place': place,
    'time': time,
    'latitude': latitude,
    'longitude': longitude,
    'expires_at': expiresAt.toIso8601String(),
    'accepted_count': acceptedCount,
    'meetup_id': meetupId,
  };

  factory ActiveMeetupRequest.fromJson(Map<String, dynamic> json) {
    return ActiveMeetupRequest(
      id: json['id']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      people: json['people']?.toString() ?? '',
      place: json['place']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -33.8688,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 151.2093,
      expiresAt: DateTime.parse(json['expires_at'].toString()),
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      meetupId: json['meetup_id']?.toString() ?? '',
    );
  }
}

class ActiveRequestStore {
  const ActiveRequestStore._();

  static const _storageKey = 'active_meetup_request';

  static Future<void> save(ActiveMeetupRequest request) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(request.toJson()));
  }

  static Future<ActiveMeetupRequest?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return null;

    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) throw const FormatException();
      final request = ActiveMeetupRequest.fromJson(json);
      if (request.id.isEmpty || !request.expiresAt.isAfter(DateTime.now())) {
        await clear();
        return null;
      }
      return request;
    } on Object {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
