import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/app_state.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'HomeWidgetProvider';
  static const String _iosWidgetName = 'HomeWidget';
  static const String _attendanceWidgetName = 'AttendanceWidgetProvider';
  static const String _kanbanWidgetName = 'KanbanWidgetProvider';

  static Future<void> updateWidget(HomeWidgetSnapshot snapshot) async {
    try {
      debugPrint('DEBUG: HomeWidgetService.updateWidget called');
      await HomeWidget.saveWidgetData<String>('next_class_label', snapshot.nextClassLabel);
      await HomeWidget.saveWidgetData<String>('next_class_time', snapshot.nextClassTime);
      await HomeWidget.saveWidgetData<double>('attendance_percentage', snapshot.attendancePercentage);
      await HomeWidget.saveWidgetData<String>('risk_label', snapshot.riskLabel);
      await HomeWidget.saveWidgetData<int>('upcoming_deadlines_count', snapshot.upcomingDeadlinesCount);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
      debugPrint('DEBUG: HomeWidgetService.updateWidget completed');
    } catch (e) {
      debugPrint('DEBUG: HomeWidgetService error: $e');
    }
  }

  /// Update the attendance widget with detailed data
  static Future<void> updateAttendanceWidget({
    required String nextClass,
    required String nextTime,
    required double currentPct,
    required double ifAttendPct,
    required double ifSkipPct,
    required String risk,
    required int safeBunks,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('att_next_class', nextClass);
      await HomeWidget.saveWidgetData<String>('att_next_time', nextTime);
      await HomeWidget.saveWidgetData<double>('att_current_pct', currentPct);
      await HomeWidget.saveWidgetData<double>('att_if_attend_pct', ifAttendPct);
      await HomeWidget.saveWidgetData<double>('att_if_skip_pct', ifSkipPct);
      await HomeWidget.saveWidgetData<String>('att_risk', risk);
      await HomeWidget.saveWidgetData<int>('att_safe_bunks', safeBunks);

      await HomeWidget.updateWidget(androidName: _attendanceWidgetName);
      debugPrint('DEBUG: Attendance widget updated');
    } catch (e) {
      debugPrint('DEBUG: Attendance widget error: $e');
    }
  }

  /// Update the kanban board widget
  static Future<void> updateKanbanWidget({
    required List<String> todoTasks,
    required List<String> doingTasks,
    required List<String> doneTasks,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('kanban_todo_count', todoTasks.length);
      await HomeWidget.saveWidgetData<int>('kanban_doing_count', doingTasks.length);
      await HomeWidget.saveWidgetData<int>('kanban_done_count', doneTasks.length);
      await HomeWidget.saveWidgetData<String>('kanban_todo_tasks', todoTasks.take(3).join('|'));
      await HomeWidget.saveWidgetData<String>('kanban_doing_tasks', doingTasks.take(3).join('|'));
      await HomeWidget.saveWidgetData<String>('kanban_done_tasks', doneTasks.take(3).join('|'));

      await HomeWidget.updateWidget(androidName: _kanbanWidgetName);
      debugPrint('DEBUG: Kanban widget updated');
    } catch (e) {
      debugPrint('DEBUG: Kanban widget error: $e');
    }
  }

  /// Register background callback for widget button actions
  static Future<void> setupBackground() async {
    try {
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('DEBUG: Widget background setup skipped (iOS?): $e');
    }
  }
}

/// Background callback for widget button interactions (attend/skip)
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;

  if (uri.host == 'attendance_attend') {
    debugPrint('Widget: ATTEND pressed');
    // We can't directly call AppState here, but we can save a flag
    await HomeWidget.saveWidgetData<bool>('pending_attend', true);
    await HomeWidget.updateWidget(androidName: 'AttendanceWidgetProvider');
  } else if (uri.host == 'attendance_skip') {
    debugPrint('Widget: SKIP pressed');
    await HomeWidget.saveWidgetData<bool>('pending_skip', true);
    await HomeWidget.updateWidget(androidName: 'AttendanceWidgetProvider');
  }
}
