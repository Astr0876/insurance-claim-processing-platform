import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/main.dart';

void main() {
  testWidgets('app renders splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const LuminaApp());
    expect(find.text('LUMINA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
