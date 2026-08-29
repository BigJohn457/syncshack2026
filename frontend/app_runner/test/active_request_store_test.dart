import 'package:app_runner/requests/active_request_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads the current stage from the backend', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/home/get/current-stage');
      return http.Response('''
        {"success":true,"data":{"stage":"rating","request_id":"r1",
        "meetup_id":"m1","activity":"Coffee","place":"Central",
        "min_people":1,"max_people":3,"meet_time":"2026-08-30T10:00:00",
        "expires_at":"2026-08-30T10:30:00","accepted_count":2}}
      ''', 200);
    });

    final current = await ActiveRequestStore.load(client: client);

    expect(current?.stage, UserMeetupStage.rating);
    expect(current?.meetupId, 'm1');
    expect(current?.activity, 'Coffee');
  });

  test('returns null when the backend has no current stage', () async {
    final client = MockClient(
      (_) async => http.Response('{"success":true,"data":null}', 200),
    );

    expect(await ActiveRequestStore.load(client: client), isNull);
  });
}
