import 'package:app_runner/rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rating page has no back action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RatePage()));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
