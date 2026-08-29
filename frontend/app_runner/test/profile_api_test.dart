import 'dart:convert';

import 'package:app_runner/profiles/profile_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetches the authenticated user profile fields', () async {
    late http.Request captured;
    final api = ProfileApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'first_name': 'Blue',
              'last_name': 'Panda',
              'email': 'blue@example.com',
              'phone': '0400000000',
              'radius': 5.5,
              'profile_image_url': 'https://example.com/avatar.jpg',
              'personalization_answers': {
                'about_me': 'Curious builder',
                'interests': 'Coffee and code',
                'ideal_meetup': 'A relaxed walk',
                'personality': 'Warm and thoughtful',
                'conversation_topics': 'Technology and travel',
              },
            },
          }),
          200,
        );
      }),
    );

    final profile = await api.fetch('user-1');

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/users/get/own-profile');
    expect(captured.url.queryParameters['id'], 'user-1');
    expect(profile.firstName, 'Blue');
    expect(profile.radius, 5.5);
    expect(profile.hasPersonalization, isTrue);
  });

  test('updates every editable database profile field', () async {
    late http.Request captured;
    final api = ProfileApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );

    await api.update(
      const UserProfile(
        firstName: 'Blue',
        lastName: 'Panda',
        email: 'blue@example.com',
        phone: '0400000000',
        radius: 5.5,
        profileImageUrl: 'https://example.com/avatar.jpg',
      ),
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/users/post/edit-profile');
    expect(jsonDecode(captured.body), {
      'first_name': 'Blue',
      'last_name': 'Panda',
      'email': 'blue@example.com',
      'phone': '0400000000',
      'radius': 5.5,
      'profile_image_url': 'https://example.com/avatar.jpg',
    });
  });

  test('saves profile personalization answers', () async {
    late http.Request captured;
    final api = ProfileApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );
    const answers = {
      'about_me': 'Curious builder',
      'interests': 'Coffee and code',
      'ideal_meetup': 'A relaxed walk',
      'personality': 'Warm and thoughtful',
      'conversation_topics': 'Technology and travel',
    };

    await api.updatePersonalization(answers);

    expect(captured.url.path, '/api/users/post/personalization');
    expect(jsonDecode(captured.body), {'answers': answers});
  });
}
