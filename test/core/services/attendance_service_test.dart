import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/attendance_service.dart';

void main() {
  group('AttendanceRecord formulas', () {
    test('computes classes needed to reach target', () {
      final record = AttendanceRecord(subject: 'OS', attended: 14, total: 20);
      expect(record.classesToReachTarget(target: 75), 4);
    });

    test('computes bunk budget above target', () {
      final record = AttendanceRecord(subject: 'Math', attended: 18, total: 20);
      expect(record.safeBunks(target: 75), 4);
    });

    test('handles target guardrails and zero totals', () {
      final record = AttendanceRecord(subject: 'CN', attended: 0, total: 0);
      expect(record.percentage, 100);
      expect(record.classesToReachTarget(target: 100), 0);
      expect(record.safeBunks(target: 0), 0);
    });
  });

  group('AttendanceService analytics', () {
    test('returns aggregate analytics', () {
      final service = AttendanceService()..loadDemoData();
      final analytics = service.overallAnalytics;
      expect(analytics.currentPercentage, greaterThan(0));
      expect(analytics.currentPercentage, lessThanOrEqualTo(100));
      expect(analytics.bunkBudget, greaterThanOrEqualTo(0));
      expect(analytics.classesNeeded, greaterThanOrEqualTo(0));
    });
  });
}
