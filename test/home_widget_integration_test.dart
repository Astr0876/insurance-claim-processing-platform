import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/providers/app_state.dart';
import 'package:lumina/core/services/home_widget_service.dart';
import 'package:lumina/app/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/features/study_hub/services/hub_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];

  void setupMock(String channelName) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(channelName), (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'saveWidgetData' || 
          methodCall.method == 'updateWidget' || 
          methodCall.method == 'setAppGroupId' ||
          methodCall.method == 'initiallyLaunchedFromHomeWidget') {
        if (methodCall.method == 'initiallyLaunchedFromHomeWidget') {
          return null; 
        }
        return true;
      }
      return null;
    });
  }

  setUp(() {
    log.clear();
    setupMock('home_widget');
    setupMock('es.antonborri.home_widget');
    setupMock('es.antonborri.home_widget/methods');
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('es.antonborri.home_widget'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('es.antonborri.home_widget/methods'), null);
  });

  test('AppState should export data to HomeWidget on initialization', () async {
    final appState = AppState();
    await appState.initialize();

    expect(log.any((call) => call.method == 'saveWidgetData' && call.arguments['id'] == 'next_class_label'), isTrue);
    expect(log.any((call) => call.method == 'updateWidget'), isTrue);
  });

  testWidgets('AppShell should navigate to Expenses when Log Spend widget action is triggered', (WidgetTester tester) async {
    // Mock the initiallyLaunchedFromHomeWidget call to return the deep link
    for (var name in ['home_widget', 'es.antonborri.home_widget', 'es.antonborri.home_widget/methods']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (MethodCall methodCall) async {
        if (methodCall.method == 'initiallyLaunchedFromHomeWidget') {
          return 'homeWidget://log_spend';
        }
        return true;
      });
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => HubService()),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );

    // Wait for splash screen to finish and navigation to happen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    // Check if Expenses screen is active. 
    expect(find.text('EXPENSES'), findsOneWidget);
  });
}
