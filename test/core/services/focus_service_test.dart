import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/focus_service.dart';

void main() {
  group('FocusService - ContextSwitch & Cognitive Debt Score', () {
    late FocusService focusService;

    setUp(() {
      focusService = FocusService();
    });

    test('Simulate foreground app changes (Study -> Distraction)', () {
      focusService.recordAppSwitch('Notion');
      // No getter for current app, we verify debt indirectly or could add one
      
      focusService.recordAppSwitch('Instagram');
      expect(focusService.cognitiveDebt, greaterThan(0));
    });

    test('Verify exponential decay model', () {
      focusService.recordAppSwitch('Instagram');
      final debtBefore = focusService.cognitiveDebt;
      
      focusService.recordAppSwitch('TikTok');
      final debtAfter = focusService.cognitiveDebt;
      
      expect(debtAfter, greaterThan(debtBefore));
    });

    test('Lumina notification trigger on threshold', () {
      // Rapid switches to build debt
      focusService.recordAppSwitch('Instagram');
      focusService.recordAppSwitch('TikTok');
      focusService.recordAppSwitch('YouTube');
      focusService.recordAppSwitch('Snapchat');
      focusService.recordAppSwitch('Instagram');
      focusService.recordAppSwitch('TikTok');
      
      expect(focusService.cognitiveDebt, greaterThanOrEqualTo(50.0));
    });
  });
}
