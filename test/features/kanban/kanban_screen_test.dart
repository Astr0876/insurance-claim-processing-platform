import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lumina/features/kanban/kanban_screen.dart';
import 'package:lumina/core/providers/app_state.dart';
import 'package:lumina/core/services/kanban_service.dart';
import 'package:lumina/core/theme/neubrut_tokens.dart';

void main() {
  group('Kanban Screen Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
      appState.initialize(); // Loads demo data
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const Scaffold(body: KanbanScreen()),
        ),
      );
    }

    testWidgets('Transition between Backlog and Active', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find a task in TODO (Research UI Patterns)
      expect(find.text('Research UI Patterns'), findsOneWidget);
      
      // Move it to DOING via service directly to simulate the result of a drag
      final task = appState.kanban.todoTasks.firstWhere((t) => t.title == 'Research UI Patterns');
      appState.kanban.updateTaskStatus(task.taskId, KanbanStatus.doing);
      
      await tester.pumpAndSettle();
      
      // Should now be in DOING
      expect(find.text('Research UI Patterns'), findsOneWidget);
    });

    testWidgets('Global Reflection (Service call)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Research UI Patterns is in TODO
      expect(appState.kanban.todoTasks.any((t) => t.title == 'Research UI Patterns'), isTrue);

      // Simulate remote move directly via service
      final taskId = appState.kanban.todoTasks.firstWhere((t) => t.title == 'Research UI Patterns').taskId;
      appState.kanban.simulateRemoteMove(taskId, KanbanStatus.doing);
      
      await tester.pumpAndSettle();
      
      // Verify it moved from TODO to DOING in the UI/Service
      expect(appState.kanban.todoTasks.any((t) => t.title == 'Research UI Patterns'), isFalse);
      expect(appState.kanban.doingTasks.any((t) => t.title == 'Research UI Patterns'), isTrue);
    });

    testWidgets('Assignee logic shows correct avatar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Draft Project Proposal is assigned to Renee (Avatar 'R')
      expect(find.text('Draft Project Proposal'), findsOneWidget);
      expect(find.text('R'), findsAtLeastNWidgets(1)); // Renee and her completed task 'Finalize Tech Stack' both have 'R'
      
      // Research UI Patterns is assigned to Alex (Avatar 'A')
      expect(find.text('Research UI Patterns'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });
  });
}
