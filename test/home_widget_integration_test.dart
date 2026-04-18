import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/providers/app_state.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  test('Home Widget - Integration & Background Updates', () async {
    final appState = AppState();
    
    // Initial state
    expect(appState.widgetSnapshot.riskLabel, 'LOW');

    // Simulate marking a class as absent to trigger update
    await appState.markAbsent('Data Structures');
    
    // Risk should potentially change based on the logic (formula in AttendanceService)
    // For now we just verify the snapshot is updated and exported
    expect(appState.widgetSnapshot.attendancePercentage, lessThan(100));
  });
}
