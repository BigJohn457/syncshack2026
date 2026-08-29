import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class RatingsApi {
  RatingsApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<void> submit({
    required String meetupId,
    required String toUserId,
    required int rating,
  }) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri('/api/rating/post/submit-rating'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meetup_id': meetupId,
          'to_user_id': toUserId,
          'rating': rating,
        }),
      );
    } on Exception {
      throw const AuthException(
        'Could not submit the rating. Check your internet connection.',
      );
    }

    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the status-based fallback for malformed server responses.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Could not submit the rating (${response.statusCode}).',
      );
    }
  }
}
