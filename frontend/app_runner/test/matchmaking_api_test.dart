import 'dart:convert';

import 'package:app_runner/matchmaking/matchmaking_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends current and candidate IDs and parses the best match', () async {
    late http.Request captured;
    final api = MatchmakingApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'user_id': 'user-3', 'score': 91},
          }),
          200,
        );
      }),
    );

    final result = await api.bestMatch(
      currentUserId: 'user-1',
      userIds: const ['user-2', 'user-3'],
    );

    expect(captured.url.path, '/api/users/post/matchmaking');
    expect(jsonDecode(captured.body), {
      'current_user_id': 'user-1',
      'user_ids': ['user-2', 'user-3'],
    });
    expect(result?.userId, 'user-3');
    expect(result?.score, 91);
  });
}
