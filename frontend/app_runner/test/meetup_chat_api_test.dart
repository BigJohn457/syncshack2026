import 'dart:convert';

import 'package:app_runner/chat/meetup_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetches and parses meetup messages', () async {
    late http.Request captured;
    final api = MeetupChatApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'meetup_id': 'meetup-1',
              'messages': [
                {
                  'id': 'message-1',
                  'sender_id': 'user-1',
                  'sender': {
                    'anonymous_name': 'Anonymous Koala',
                    'img_url': null,
                  },
                  'message': 'Hello!',
                  'created_at': '2026-08-30T10:15:00+00:00',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final messages = await api.fetchMessages('meetup-1');

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/meetup-chat/get/all-messages');
    expect(captured.url.queryParameters['meetup_id'], 'meetup-1');
    expect(messages.single.senderName, 'Anonymous Koala');
    expect(messages.single.message, 'Hello!');
  });

  test('sends a message using the documented payload', () async {
    late http.Request captured;
    final api = MeetupChatApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'meetup_id': 'meetup-1',
              'message': {
                'id': 'message-2',
                'sender_id': 'user-1',
                'sender': {
                  'anonymous_name': 'Anonymous Fox',
                  'img_url': 'https://example.com/avatar.jpg',
                },
                'message': 'On my way',
                'created_at': '2026-08-30T10:20:00+00:00',
              },
            },
          }),
          201,
        );
      }),
    );

    final message = await api.sendMessage(
      meetupId: 'meetup-1',
      message: 'On my way',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/meetup-chat/post/send-message');
    expect(jsonDecode(captured.body), {
      'meetup_id': 'meetup-1',
      'message': 'On my way',
    });
    expect(message.id, 'message-2');
    expect(message.senderImageUrl, 'https://example.com/avatar.jpg');
  });
}
