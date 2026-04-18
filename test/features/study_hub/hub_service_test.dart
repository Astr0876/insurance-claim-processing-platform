import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/study_hub/services/hub_service.dart';

void main() {
  group('HubService - Study Squads Flow Trend', () {
    late HubService hubService;

    setUp(() {
      hubService = HubService();
    });

    test('Verify focus data is anonymized and correctly visualized', () {
      // Squad has 4 members with different focus scores
      final rawScores = [90.0, 85.0, 70.0, 65.0];
      
      hubService.updateFlowTrend(rawScores);
      
      // Verification: The squad only sees the average, losing individual identity
      expect(hubService.flowTrend.length, 1);
      
      final expectedAvg = (90 + 85 + 70 + 65) / 4;
      expect(hubService.flowTrend.first, expectedAvg);
      
      print('Anonymized Flow Trend Avg: ${hubService.flowTrend.first}%');
    });

    test('Flow Trend stores a history of trends', () {
      hubService.updateFlowTrend([80.0, 90.0]);
      hubService.updateFlowTrend([85.0, 75.0]);
      hubService.updateFlowTrend([90.0, 80.0]);
      
      expect(hubService.flowTrend.length, 3);
      expect(hubService.flowTrend[0], 85.0);
      expect(hubService.flowTrend[1], 80.0);
      expect(hubService.flowTrend[2], 85.0);
    });
  });
}
