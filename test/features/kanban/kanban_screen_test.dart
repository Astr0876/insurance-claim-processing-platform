import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/kanban_service.dart';
import 'package:lumina/features/kanban/kanban_screen.dart';

import '../../test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  KanbanService buildService() {
    final service = KanbanService();
    service.loadDemoData();
    return service;
  }

  testWidgets('hub renders multiple boards', (tester) async {
    final kanban = buildService();

    await tester.pumpWidget(
      MaterialApp(home: KanbanScreen(kanbanService: kanban)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Personal Focus'), findsOneWidget);
    expect(find.text('Squad Sprint'), findsOneWidget);
  });

  testWidgets('board tap navigates to detail', (tester) async {
    final kanban = buildService();

    await tester.pumpWidget(
      MaterialApp(home: KanbanScreen(kanbanService: kanban)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('board-card-board-shared')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('color-rule-indicator')), findsOneWidget);
    expect(find.text('ASSIGNEE COLORS ACTIVE'), findsOneWidget);
  });

  testWidgets('private vs shared color rule indicators are shown', (
    tester,
  ) async {
    final kanban = buildService();

    await tester.pumpWidget(
      MaterialApp(home: KanbanScreen(kanbanService: kanban)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('board-card-board-personal')));
    await tester.pumpAndSettle();
    expect(find.text('STATUS COLORS ACTIVE'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('board-card-board-shared')));
    await tester.pumpAndSettle();
    expect(find.text('ASSIGNEE COLORS ACTIVE'), findsOneWidget);
  });

  testWidgets('my tasks filtering shows only current user tasks', (
    tester,
  ) async {
    final kanban = buildService();

    await tester.pumpWidget(
      MaterialApp(home: KanbanScreen(kanbanService: kanban)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('board-card-board-shared')));
    await tester.pumpAndSettle();

    expect(find.text('Plan sprint board'), findsOneWidget);
    expect(find.text('Review PR checklist'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-mine')));
    await tester.pumpAndSettle();

    expect(find.text('Plan sprint board'), findsOneWidget);
    expect(find.text('Review PR checklist'), findsNothing);
  });
}
