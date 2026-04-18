import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/main.dart';

void main() {
  testWidgets('Splash screen shows LUMINA', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LuminaApp());

    // Verify that splash screen shows LUMINA
    expect(find.text('LUMINA'), findsOneWidget);

    // Advance time to allow timers to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
