import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/focus_service.dart';
import '../services/timetable_service.dart';
import '../services/assistant_service.dart';
import '../services/kanban_service.dart';
import '../services/latex_service.dart';
import '../services/calendar_service.dart';
import '../services/ai_model_service.dart';
import '../../features/expenses/controllers/expense_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/home_widget_service.dart';

class HomeWidgetSnapshot {
  final String nextClassLabel;
  final String nextClassTime;
  final double attendancePercentage;
  final String riskLabel;
  final int upcomingDeadlinesCount;

  const HomeWidgetSnapshot({
    required this.nextClassLabel,
    required this.nextClassTime,
    required this.attendancePercentage,
    required this.riskLabel,
    required this.upcomingDeadlinesCount,
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
  final AIModelService aiModels = AIModelService();

  AppState() {
    assistant.addListener(notifyListeners);
    expenses.addListener(notifyListeners);
    latex.addListener(notifyListeners);
    calendar.addListener(notifyListeners);
    aiModels.addListener(notifyListeners);
    
    // Listen for auth changes to fetch data
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        // User logged in: Fetch all data
        timetable.fetchTimetable();
        attendance.fetchRecords();
        kanban.fetchTasks();
        focus.fetchSessions();
        expenses.fetchTransactions();
      } else {
        // Clear records on sign out
        _studentName = 'Student';
        _isInitialized = false;
        timetable.loadDemoData(); 
        attendance.loadDemoData();
        kanban.loadDemoData();
        focus.loadDemoData();
        expenses.clearAll();
      }
    });
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  HomeWidgetSnapshot _widgetSnapshot = const HomeWidgetSnapshot(
    nextClassLabel: 'No class',
    nextClassTime: '--',
    attendancePercentage: 100,
    riskLabel: 'LOW',
    upcomingDeadlinesCount: 0,
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

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // 1. Fetch data from Supabase in parallel
      await Future.wait([
        timetable.fetchTimetable(),
        attendance.fetchRecords(),
        kanban.fetchTasks(),
        focus.fetchSessions(),
        expenses.fetchTransactions(),
      ]);
      
      // 2. Fetch profile info
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('student_name')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null) {
        _studentName = profile['student_name'] ?? 'Student';
      }
    } else {
      // Not logged in: Show demo data for trial (optional)
      timetable.loadDemoData();
      attendance.loadDemoData();
      kanban.loadDemoData();
      focus.loadDemoData();
      calendar.loadDemoData();
    }

    await _refreshWidgetSnapshot();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> markAttended(String subject) async {
    await attendance.markAttended(subject);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<void> markAbsent(String subject) async {
    await attendance.markAbsent(subject);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  Future<TimetableImportResult> importTimetableFile({
    required String filePath,
    required TimetableImportType type,
  }) {
    return timetable.importTimetableFile(filePath: filePath, type: type);
  }

  Future<void> applyImportedTimetable(List<ParsedClassSlot> slots, {Map<String, dynamic>? fullJson}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user != null) {
      try {
        // 1. Save slots to timetable_entries
        // First, clear existing entries if user wants a full replace, or just append
        // For simplicity, let's append but in a real app we might ask.
        final entriesToInsert = slots.map((s) => {
          'user_id': user.id,
          'day': s.day,
          'subject': s.subject,
          'start_time': _toDisplayTime(s.startTime24),
          'room': s.room,
          'duration_minutes': s.durationMinutes,
        }).toList();

        await client.from('timetable_entries').insert(entriesToInsert);

        // 2. Save OCR audit if fullJson is present
        if (fullJson != null) {
          await timetable.saveOcrExtraction(fullJson);
          
          // 3. Process enriched subject data if present in 'subjects' list
          if (fullJson.containsKey('subjects')) {
            final subjectsData = fullJson['subjects'] as List<dynamic>;
            for (final sub in subjectsData) {
              if (sub is Map<String, dynamic>) {
                final name = sub['name'] as String?;
                if (name != null) {
                  await attendance.addSubject(name);
                  // Update with faculty/frequency if they exist
                  await client.from('attendance').update({
                    if (sub.containsKey('faculty')) 'faculty': sub['faculty'],
                    if (sub.containsKey('weekly_frequency')) 'weekly_frequency': sub['weekly_frequency'],
                  }).match({'user_id': user.id, 'subject': name});
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error applying and saving timetable: $e');
      }
    }

    timetable.applyImportedSchedule(slots);
    attendance.syncSubjects(timetable.subjects);
    await _refreshWidgetSnapshot();
    notifyListeners();
  }

  String _toDisplayTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    return '$h:${m.toString().padLeft(2, '0')} $ampm';
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
    String nextClassLabel = 'No class';
    String nextClassTime = '--';
    double attendancePct = attendance.overallPercentage;
    String risk = attendancePct < 60
        ? 'HIGH'
        : attendancePct < 75
            ? 'MEDIUM'
            : 'LOW';
    int deadlinesCount = kanban.todoTasks.length;

    try {
      // 1. Next Class from Timetable Service
      final nextClass = timetable.getNextClass();
      if (nextClass != null) {
        nextClassLabel = nextClass.subject;
        nextClassTime = nextClass.time;
      }
    } catch (e) {
      debugPrint('Error refreshing widget snapshot: $e');
    }

    final newSnapshot = HomeWidgetSnapshot(
      nextClassLabel: nextClassLabel,
      nextClassTime: nextClassTime,
      attendancePercentage: attendancePct,
      riskLabel: risk,
      upcomingDeadlinesCount: deadlinesCount,
    );

    _widgetSnapshot = newSnapshot;
    await HomeWidgetService.updateWidget(newSnapshot);

    // Update Attendance Widget with attend/skip predictions
    final totalAttended = attendance.records.values.fold<int>(0, (s, r) => s + r.attended);
    final totalClasses = attendance.records.values.fold<int>(0, (s, r) => s + r.total);
    final ifAttendPct = totalClasses > 0 ? ((totalAttended + 1) / (totalClasses + 1)) * 100 : 100.0;
    final ifSkipPct = totalClasses > 0 ? (totalAttended / (totalClasses + 1)) * 100 : 0.0;
    
    await HomeWidgetService.updateAttendanceWidget(
      nextClass: nextClassLabel,
      nextTime: nextClassTime,
      currentPct: attendancePct,
      ifAttendPct: ifAttendPct,
      ifSkipPct: ifSkipPct,
      risk: risk,
      safeBunks: attendance.totalSafeBunks,
    );

    // Update Kanban Widget
    await HomeWidgetService.updateKanbanWidget(
      todoTasks: kanban.todoTasks.map((t) => t.title).toList(),
      doingTasks: kanban.doingTasks.map((t) => t.title).toList(),
      doneTasks: kanban.doneTasks.map((t) => t.title).toList(),
    );
  }
}

