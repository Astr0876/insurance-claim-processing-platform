import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/app_state.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'HomeWidgetProvider';
  static const String _attendanceWidgetName = 'AttendanceWidgetProvider';
  static const String _kanbanWidgetName = 'KanbanWidgetProvider';
  static const String _appGroupId = 'group.lockin.widget';

  static bool _isSetup = false;

  static Future<void> _ensureSetup() async {
    if (!_isSetup) {
      try {
        await HomeWidget.setAppGroupId(_appGroupId);
        _isSetup = true;
      } catch (e) {
        debugPrint('DEBUG: HomeWidget setAppGroupId error: $e');
      }
    }
  }

  static Future<void> updateWidget(HomeWidgetSnapshot snapshot) async {
    try {
      await _ensureSetup();
      await HomeWidget.saveWidgetData<String>('next_class_label', snapshot.nextClassLabel);
      await HomeWidget.saveWidgetData<String>('next_class_time', snapshot.nextClassTime);
      await HomeWidget.saveWidgetData<String>('attendance_percentage', snapshot.attendancePercentage.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('risk_label', snapshot.riskLabel);
      await HomeWidget.saveWidgetData<String>('upcoming_deadlines_count', snapshot.upcomingDeadlinesCount.toString());

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
      debugPrint('DEBUG: Dashboard widget updated');
    } catch (e) {
      debugPrint('DEBUG: Dashboard widget error: $e');
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
      await _ensureSetup();
      // Save all values as strings — Kotlin side parses them
      await HomeWidget.saveWidgetData<String>('att_next_class', nextClass);
      await HomeWidget.saveWidgetData<String>('att_next_time', nextTime);
      await HomeWidget.saveWidgetData<String>('att_current_pct', currentPct.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('att_if_attend_pct', ifAttendPct.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('att_if_skip_pct', ifSkipPct.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('att_risk', risk);
      await HomeWidget.saveWidgetData<String>('att_safe_bunks', safeBunks.toString());

      await HomeWidget.updateWidget(androidName: _attendanceWidgetName);
      debugPrint('DEBUG: Attendance widget updated — $nextClass $currentPct%');
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
      await _ensureSetup();
      await HomeWidget.saveWidgetData<String>('kanban_todo_count', todoTasks.length.toString());
      await HomeWidget.saveWidgetData<String>('kanban_doing_count', doingTasks.length.toString());
      await HomeWidget.saveWidgetData<String>('kanban_done_count', doneTasks.length.toString());
      await HomeWidget.saveWidgetData<String>('kanban_todo_tasks', todoTasks.take(3).join('|'));
      await HomeWidget.saveWidgetData<String>('kanban_doing_tasks', doingTasks.take(3).join('|'));
      await HomeWidget.saveWidgetData<String>('kanban_done_tasks', doneTasks.take(3).join('|'));

      await HomeWidget.updateWidget(androidName: _kanbanWidgetName);
      debugPrint('DEBUG: Kanban widget updated — ${todoTasks.length}/${doingTasks.length}/${doneTasks.length}');
    } catch (e) {
      debugPrint('DEBUG: Kanban widget error: $e');
    }
  }

  /// Register background callback for widget button actions
  static Future<void> setupBackground() async {
    try {
      await _ensureSetup();
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('DEBUG: Widget background setup skipped: $e');
    }
  }
}

/// Background callback for widget button interactions (attend/skip)
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;

  if (uri.host == 'attendance_attend') {
    debugPrint('Widget: ATTEND pressed');
    await HomeWidget.saveWidgetData<String>('pending_attend', 'true');
    await HomeWidget.updateWidget(androidName: 'AttendanceWidgetProvider');
  } else if (uri.host == 'attendance_skip') {
    debugPrint('Widget: SKIP pressed');
    await HomeWidget.saveWidgetData<String>('pending_skip', 'true');
    await HomeWidget.updateWidget(androidName: 'AttendanceWidgetProvider');
  }
}
