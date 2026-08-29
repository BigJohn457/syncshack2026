import 'package:app_runner/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat fits a narrow phone and has no back action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPage(
          activity: 'A meetup activity with a long title',
          place: 'A long meetup location that must not overflow',
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Reveal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
