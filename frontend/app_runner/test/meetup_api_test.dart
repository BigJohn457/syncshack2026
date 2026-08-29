import 'dart:convert';

import 'package:app_runner/meetups/meetup_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('accepts an invitation with its meetup ID', () async {
    late http.Request captured;
    final api = MeetupApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );

    await api.acceptInvitation('meetup-1');

    expect(captured.url.path, '/api/meetup/post/accept-invitation');
    expect(jsonDecode(captured.body), {'meetup_id': 'meetup-1'});
  });

  test('fetches participant status for searching polling', () async {
    late http.Request captured;
    final api = MeetupApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'meetup_id': 'meetup-1',
              'request_id': 'request-1',
              'meetup_participant': {
                'exists': true,
                'attendance_status': 'joined',
              },
              'request_participant': {'exists': true, 'status': 'accepted'},
            },
          }),
          200,
        );
      }),
    );

    final status = await api.participantStatus('meetup-1');

    expect(captured.url.path, '/api/meetup/get/participant-status');
    expect(captured.url.queryParameters['meetup_id'], 'meetup-1');
    expect(status.hasJoined, isTrue);
  });

  test('fetches active meetup participants for accepted count', () async {
    final api = MeetupApi(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'meetup_id': 'meetup-1',
              'participants': [
                {
                  'user_id': 'user-1',
                  'attendance_status': 'joined',
                  'is_reveal': false,
                },
                {
                  'user_id': 'user-2',
                  'attendance_status': 'cancelled',
                  'is_reveal': true,
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final participants = await api.participants('meetup-1');

    expect(participants.length, 2);
    expect(participants.where((item) => item.isActive).length, 1);
  });

  test('reveals the logged-in profile to meetup participants', () async {
    late http.Request captured;
    final api = MeetupApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );

    await api.revealProfile('meetup-1');

    expect(captured.url.path, '/api/meetup/post/reveal-profile');
    expect(jsonDecode(captured.body), {'meetup_id': 'meetup-1'});
  });

  test('loads an anonymous participant profile for rating', () async {
    late http.Request captured;
    final api = MeetupApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'anonymous_name': 'Anonymous Panda',
              'profile_image_url': null,
              'reliability_score': 95,
            },
          }),
          200,
        );
      }),
    );

    final profile = await api.anonymousProfile('user-2');

    expect(captured.url.path, '/api/meetup/get/all-anonymous-profiles');
    expect(captured.url.queryParameters['id'], 'user-2');
    expect(profile.name, 'Anonymous Panda');
  });
}
