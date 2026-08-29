import 'dart:convert';

import 'package:app_runner/auth/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('logs out through the backend session endpoint', () async {
    late http.Request captured;
    final api = AuthApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    await api.logout();

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/auth/post/logout');
  });
}
