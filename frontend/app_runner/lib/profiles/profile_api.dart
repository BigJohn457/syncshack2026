import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.radius,
    this.profileImageUrl,
    this.personalizationAnswers = const {},
    this.matchmaking = false,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final double radius;
  final String? profileImageUrl;
  final Map<String, String> personalizationAnswers;
  final bool matchmaking;
  bool get hasPersonalization =>
      personalizationAnswers.length >= 5 &&
      personalizationAnswers.values.every((value) => value.trim().isNotEmpty);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['profile_image_url']?.toString().trim();
    return UserProfile(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      radius: (json['radius'] as num?)?.toDouble() ?? 0,
      profileImageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      personalizationAnswers:
          (json['personalization_answers'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
      matchmaking: json['matchmaking'] == 1 || json['matchmaking'] == true,
    );
  }
}

class ProfileApi {
  ProfileApi({http.Client? client}) : _client = client ?? createHttpClient();
  final http.Client _client;

  Future<UserProfile> fetch(String userId) async {
    final uri = ApiConfig.uri(
      '/api/users/get/own-profile',
    ).replace(queryParameters: {'id': userId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid profile.');
    }
    return UserProfile.fromJson(data);
  }

  Future<void> update(UserProfile profile) async {
    await _request(
      () => _client.post(
        ApiConfig.uri('/api/users/post/edit-profile'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': profile.firstName,
          'last_name': profile.lastName,
          'email': profile.email,
          'phone': profile.phone,
          'radius': profile.radius,
          'profile_image_url': profile.profileImageUrl,
        }),
      ),
    );
  }

  Future<void> updatePersonalization(Map<String, String> answers) async {
    await _request(
      () => _client.post(
        ApiConfig.uri('/api/users/post/personalization'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'answers': answers}),
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request();
    } on Exception {
      throw const AuthException(
        'Could not connect to your profile. Check your internet connection.',
      );
    }
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the status-based fallback for malformed responses.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Profile request failed (${response.statusCode}).',
      );
    }
    return payload;
  }
}
