import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/focus_service.dart';
import '../services/timetable_service.dart';
import '../services/assistant_service.dart';
import '../services/kanban_service.dart';
import '../services/latex_service.dart';
import '../services/calendar_service.dart';
import '../../features/expenses/controllers/expense_controller.dart';
import '../services/home_widget_service.dart';

class HomeWidgetSnapshot {
  final String nextClassLabel;
  final String nextClassTime;
  final double attendancePercentage;
  final String riskLabel;

  const HomeWidgetSnapshot({
    required this.nextClassLabel,
    required this.nextClassTime,
    required this.attendancePercentage,
    required this.riskLabel,
  });
}

class AppState extends ChangeNotifier {
  final AttendanceService attendance = AttendanceService();
  final FocusService focus = FocusService();
  final TimetableService timetable = TimetableService();
  final AssistantService assistant = AssistantService();
  final KanbanService kanban = KanbanService();
  final LaTeXService latex = LaTeXService();
  final ExpenseController expenses = ExpenseController();
  final CalendarService calendar = CalendarService();

  AppState() {
    assistant.addListener(notifyListeners);
    expenses.addListener(notifyListeners);
    latex.addListener(notifyListeners);
    calendar.addListener(notifyListeners);
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  HomeWidgetSnapshot _widgetSnapshot = const HomeWidgetSnapshot(
    nextClassLabel: 'No class',
    nextClassTime: '--',
    attendancePercentage: 100,
    riskLabel: 'LOW',
  );
  HomeWidgetSnapshot get widgetSnapshot => _widgetSnapshot;

  String _studentName = 'Student';
  String get studentName => _studentName;

  double _batteryLevel = 100;
  double get batteryLevel => _batteryLevel;
  bool _showBatteryAlert = false;
  bool get showBatteryAlert => _showBatteryAlert;

  void setStudentName(String name) {
    _studentName = name;
    notifyListeners();
  }

  void simulateBatteryDrop(double level) {
    _batteryLevel = level;
    if (_batteryLevel <= 15) {
      _showBatteryAlert = true;
    }
    notifyListeners();
  }

  void dismissBatteryAlert() {
    _showBatteryAlert = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    timetable.loadDemoData();
    attendance.loadDemoData();
    focus.loadDemoData();
    assistant.loadDemoDocument();
    await _refreshWidgetSnapshot();
    kanban.loadDemoData();
    latex.loadDemoData();
    calendar.loadDemoData();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> markAttended(String subject) async {
    attendance.markAttended(subject);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<void> markAbsent(String subject) async {
    attendance.markAbsent(subject);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<TimetableImportResult> importTimetableFile({
    required String filePath,
    required TimetableImportType type,
  }) {
    return timetable.importTimetableFile(filePath: filePath, type: type);
  }

  Future<void> applyImportedTimetable(List<ParsedClassSlot> slots) async {
    timetable.applyImportedSchedule(slots);
    attendance.syncSubjects(timetable.subjects);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<void> addManualClass(String day, TimetableEntry entry) async {
    timetable.addManualEntry(day, entry);
    attendance.addSubject(entry.subject);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  double get stressLevel {
    final attendanceRisk = (100 - attendance.overallPercentage).clamp(0.0, 100.0);
    final deadlineProximity = calendar.deadlineProximityScore;
    final cognitiveDebt = (kanban.todoTasks.length * 12.0).clamp(0.0, 100.0);
    double stress = (0.4 * attendanceRisk) + (0.4 * deadlineProximity) + (0.2 * cognitiveDebt);
    final focusScore = focus.todayFocusScore;
    if (focusScore >= 80) {
      stress -= 10;
    } else if (focusScore < 40) {
      stress += 10;
    }
    return stress.clamp(0, 100);
  }

  Color get stressColor {
    final state = calendar.stressState;
    if (state == StressState.red) return const Color(0xFFFF6B6B);
    final s = stressLevel;
    if (s < 30) return const Color(0xFF00E676);
    if (s < 50) return const Color(0xFF76FF03);
    if (s < 70) return const Color(0xFFFFD93D);
    if (s < 85) return const Color(0xFFFF9800);
    return const Color(0xFFFF6B6B);
  }

  String get stressLabel {
    final state = calendar.stressState;
    if (state == StressState.red) return 'Red Alert! 🚨';
    final s = stressLevel;
    if (s < 30) return 'Zen Mode 🧘';
    if (s < 50) return 'Doing Good 😊';
    if (s < 70) return 'Moderate 😐';
    if (s < 85) return 'Getting Hectic 😰';
    return 'Overload! 🔥';
  }

  Future<void> refresh() async {
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<void> _refreshWidgetSnapshot() async {
    final nextClass = timetable.getNextClass();
    final attendancePct = attendance.overallPercentage;
    final risk = attendancePct < 60
        ? 'HIGH'
        : attendancePct < 75
        ? 'MEDIUM'
        : 'LOW';

    final newSnapshot = HomeWidgetSnapshot(
      nextClassLabel: nextClass?.subject ?? 'No class',
      nextClassTime: nextClass?.time ?? '--',
      attendancePercentage: attendancePct,
      riskLabel: risk,
    );

    _widgetSnapshot = newSnapshot;
    await HomeWidgetService.updateWidget(newSnapshot);
  }
}
