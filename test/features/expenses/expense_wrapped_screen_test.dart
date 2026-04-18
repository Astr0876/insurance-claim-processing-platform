import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/expenses/controllers/expense_controller.dart';
import 'package:lumina/features/expenses/screens/expense_wrapped_screen.dart';
import '../../test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  testWidgets('ExpenseWrappedScreen shows correct vibe for Foodie', (WidgetTester tester) async {
    final controller = ExpenseController();
    controller.handleInput('Spent 6000 on food');
    
    await tester.pumpWidget(MaterialApp(
      home: ExpenseWrappedScreen(controller: controller),
    ));

    // Page 1: Intro
    expect(find.text('EXPENSE\nWRAPPED'), findsOneWidget);
    expect(find.text('₹6000'), findsOneWidget);

    // Swipe to next pages until Vibe Page (Page 4)
    final pageView = find.byType(PageView);
    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle(); // Page 2: Top Category
    expect(find.text('FOOD'), findsOneWidget);

    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle(); // Page 3: Breakdown
    expect(find.text('THE\nBREAKDOWN'), findsOneWidget);

    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle(); // Page 4: Vibe
    expect(find.text('THE FOODIE'), findsOneWidget);
  });

  testWidgets('ExpenseWrappedScreen shows correct vibe for Explorer', (WidgetTester tester) async {
    final controller = ExpenseController();
    controller.handleInput('Spent 2000 on travel');
    
    await tester.pumpWidget(MaterialApp(
      home: ExpenseWrappedScreen(controller: controller),
    ));

    final pageView = find.byType(PageView);
    // Page 1 -> 2 -> 3 -> 4
    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(pageView, const Offset(-400, 0));
    await tester.pumpAndSettle();
    
    expect(find.text('THE EXPLORER'), findsOneWidget);
  });
}
