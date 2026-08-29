import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class MatchmakingResult {
  const MatchmakingResult({required this.userId, required this.score});
  final String userId;
  final int score;
}

class MatchmakingApi {
  MatchmakingApi({http.Client? client})
    : _client = client ?? createHttpClient();
  final http.Client _client;

  Future<void> setEnabled(bool enabled) async {
    await _post('/api/users/post/matchmaking-toggle', {'enabled': enabled});
  }

  Future<MatchmakingResult?> bestMatch({
    required String currentUserId,
    required List<String> userIds,
  }) async {
    final payload = await _post('/api/users/post/matchmaking', {
      'current_user_id': currentUserId,
      'user_ids': userIds,
    });
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return null;
    final userId = data['user_id']?.toString() ?? '';
    if (userId.isEmpty) return null;
    return MatchmakingResult(
      userId: userId,
      score: (data['score'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Exception {
      throw const AuthException('Could not connect to matchmaking.');
    }
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ?? 'Matchmaking request failed.',
      );
    }
    return payload;
  }
}
