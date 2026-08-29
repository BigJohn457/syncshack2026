import 'dart:convert';

import 'package:app_runner/auth/auth_api.dart';
import 'package:app_runner/ratings/ratings_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('submits a rating using the documented API payload', () async {
    late http.Request captured;
    final api = RatingsApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Rating submitted successfully',
            'data': {
              'meetup_id': 'meetup-1',
              'to_user_id': 'user-2',
              'rating': 5,
            },
          }),
          201,
        );
      }),
    );

    await api.submit(meetupId: 'meetup-1', toUserId: 'user-2', rating: 5);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/rating/post/submit-rating');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(jsonDecode(captured.body), {
      'meetup_id': 'meetup-1',
      'to_user_id': 'user-2',
      'rating': 5,
    });
  });

  test('surfaces the backend rating error', () async {
    final api = RatingsApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'error': 'rating already submitted'}),
          409,
        ),
      ),
    );

    expect(
      () => api.submit(meetupId: 'meetup-1', toUserId: 'user-2', rating: 4),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'rating already submitted',
        ),
      ),
    );
  });
}
