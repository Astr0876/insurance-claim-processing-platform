import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/study_hub/services/hub_service.dart';
import '../../test_helper.dart';

void main() {
  group('HubService - Study Squads Flow Trend', () {
    late HubService hubService;

    setUpAll(() async {
      await initializeSupabaseForTest();
    });

    setUp(() {
      hubService = HubService();
    });

    test('Verify focus data is anonymized and correctly visualized', () {
      // Simulate raw focus scores from multiple users
      final rawScores = [85.0, 70.0, 90.0, 65.0];
      
      hubService.updateFlowTrend(rawScores);
      
      expect(hubService.flowTrend.length, 1);
      
      // Anonymization check: individual scores should not be stored
      expect(hubService.flowTrend.first, 77.5); // Average of rawScores
    });
  });
}
