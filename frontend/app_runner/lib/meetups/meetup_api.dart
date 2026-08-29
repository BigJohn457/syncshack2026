import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class ParticipantStatus {
  const ParticipantStatus({
    required this.meetupId,
    required this.requestId,
    required this.attendanceStatus,
    required this.requestStatus,
  });
  final String meetupId;
  final String requestId;
  final String? attendanceStatus;
  final String? requestStatus;

  bool get hasJoined =>
      const {'joined', 'attended'}.contains(attendanceStatus) ||
      requestStatus == 'accepted';

  factory ParticipantStatus.fromJson(Map<String, dynamic> json) {
    final meetup = json['meetup_participant'];
    final request = json['request_participant'];
    return ParticipantStatus(
      meetupId: json['meetup_id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      attendanceStatus: meetup is Map<String, dynamic>
          ? meetup['attendance_status']?.toString()
          : null,
      requestStatus: request is Map<String, dynamic>
          ? request['status']?.toString()
          : null,
    );
  }
}

class MeetupParticipant {
  const MeetupParticipant({
    required this.userId,
    required this.attendanceStatus,
    required this.isReveal,
  });

  final String userId;
  final String attendanceStatus;
  final bool isReveal;

  bool get isActive =>
      const {'joined', 'attended', 'finished'}.contains(attendanceStatus);

  factory MeetupParticipant.fromJson(Map<String, dynamic> json) {
    return MeetupParticipant(
      userId: json['user_id']?.toString() ?? '',
      attendanceStatus: json['attendance_status']?.toString() ?? '',
      isReveal: json['is_reveal'] == true,
    );
  }
}

class AnonymousMeetupProfile {
  const AnonymousMeetupProfile({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;
}

class SharedMeetupProfile {
  const SharedMeetupProfile({
    required this.name,
    required this.reliabilityScore,
    this.imageUrl,
    this.answers = const {},
  });

  final String name;
  final double reliabilityScore;
  final String? imageUrl;
  final Map<String, String> answers;
}

class MeetupApi {
  MeetupApi({http.Client? client}) : _client = client ?? createHttpClient();
  final http.Client _client;

  Future<void> acceptInvitation(String meetupId) async {
    await _request(
      () => _client.post(
        ApiConfig.uri('/api/meetup/post/accept-invitation'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId}),
      ),
    );
  }

  Future<ParticipantStatus> participantStatus(String meetupId) async {
    final uri = ApiConfig.uri(
      '/api/meetup/get/participant-status',
    ).replace(queryParameters: {'meetup_id': meetupId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException(
        'The server returned an invalid meetup status.',
      );
    }
    return ParticipantStatus.fromJson(data);
  }

  Future<List<MeetupParticipant>> participants(String meetupId) async {
    final uri = ApiConfig.uri(
      '/api/meetup/get/all-participants',
    ).replace(queryParameters: {'meetup_id': meetupId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    final rows = data is Map<String, dynamic> ? data['participants'] : null;
    if (rows is! List) {
      throw const AuthException(
        'The server returned an invalid participant list.',
      );
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MeetupParticipant.fromJson)
        .where((participant) => participant.userId.isNotEmpty)
        .toList();
  }

  Future<void> revealProfile(String meetupId) async {
    await _request(
      () => _client.post(
        ApiConfig.uri('/api/meetup/post/reveal-profile'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId}),
      ),
    );
  }

  Future<void> finishParticipation(String meetupId) async {
    await _request(
      () => _client.post(
        ApiConfig.uri('/api/meetup/post/finish-participation'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId}),
      ),
    );
  }

  Future<AnonymousMeetupProfile> anonymousProfile(String userId) async {
    final uri = ApiConfig.uri(
      '/api/meetup/get/all-anonymous-profiles',
    ).replace(queryParameters: {'id': userId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException(
        'The server returned an invalid participant profile.',
      );
    }
    final image = data['profile_image_url']?.toString().trim();
    return AnonymousMeetupProfile(
      name: data['anonymous_name']?.toString() ?? 'Anonymous member',
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }

  Future<SharedMeetupProfile> sharedProfile(String userId) async {
    final uri = ApiConfig.uri(
      '/api/meetup/get/all-users-profiles',
    ).replace(queryParameters: {'id': userId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid profile.');
    }
    final image = data['profile_image_url']?.toString().trim();
    return SharedMeetupProfile(
      name: '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
      reliabilityScore: (data['reliability_score'] as num?)?.toDouble() ?? 0,
      imageUrl: image == null || image.isEmpty ? null : image,
      answers:
          (data['personalization_answers'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() call,
  ) async {
    http.Response response;
    try {
      response = await call();
    } on Exception {
      throw const AuthException('Could not connect to the meetup.');
    }
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the status fallback.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Meetup request failed (${response.statusCode}).',
      );
    }
    return payload;
  }
}
