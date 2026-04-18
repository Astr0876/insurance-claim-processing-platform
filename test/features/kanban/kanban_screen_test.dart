import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:lumina/core/providers/app_state.dart';
import 'package:lumina/features/kanban/kanban_screen.dart';
import 'package:lumina/core/services/kanban_service.dart';
import '../../test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  testWidgets('Multi-User Kanban - Team Alignment & Status Transitions', (WidgetTester tester) async {
    final appState = AppState();
    
    // Seed initial data
    appState.kanban.loadDemoData();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(body: KanbanScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify groups exist
    expect(find.text('WHAT I WANT TO DO'), findsOneWidget);
    expect(find.text('WHAT I AM DOING'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);

    // Verify specific task exists
    expect(find.text('Research UI Patterns'), findsOneWidget);

    // Simulate remote move directly via service
    final taskId = appState.kanban.todoTasks.firstWhere((t) => t.title == 'Research UI Patterns').taskId;
    appState.kanban.updateTaskStatus(taskId, KanbanStatus.doing, isRemote: true);
    
    await tester.pumpAndSettle();
    
    // Verify it moved from TODO to DOING in the UI/Service
    expect(appState.kanban.todoTasks.any((t) => t.title == 'Research UI Patterns'), isFalse);
    expect(appState.kanban.doingTasks.any((t) => t.title == 'Research UI Patterns'), isTrue);
  });
}
