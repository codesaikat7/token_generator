import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:queuemed/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TokenGeneratorApp());

    // Verify that the app title is displayed
    expect(find.text('QueueMed'), findsOneWidget);
  });
}
