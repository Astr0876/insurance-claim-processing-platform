import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/focus_service.dart';
import '../services/timetable_service.dart';
import '../services/assistant_service.dart';

class AppState extends ChangeNotifier {
  final AttendanceService attendance = AttendanceService();
  final FocusService focus = FocusService();
  final TimetableService timetable = TimetableService();
  final AssistantService assistant = AssistantService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Student name for personalization
  String _studentName = 'Student';
  String get studentName => _studentName;

  void setStudentName(String name) {
    _studentName = name;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load demo data for all services
    timetable.loadDemoData();
    attendance.loadDemoData();
    focus.loadDemoData();
    assistant.loadDemoDocument();

    _isInitialized = true;
    notifyListeners();
  }

  // Attendance actions
  void markAttended(String subject) {
    attendance.markAttended(subject);
    notifyListeners();
  }

  void markAbsent(String subject) {
    attendance.markAbsent(subject);
    notifyListeners();
  }

  // Stress level (0-100)
  double get stressLevel {
    double stress = 50; // base

    // High attendance reduces stress
    final att = attendance.overallPercentage;
    if (att >= 85) {
      stress -= 20;
    } else if (att >= 75) {
      stress -= 10;
    } else if (att < 60) {
      stress += 25;
    } else if (att < 75) {
      stress += 15;
    }

    // Good focus reduces stress
    final focusScore = focus.todayFocusScore;
    if (focusScore >= 80) {
      stress -= 15;
    } else if (focusScore >= 60) {
      stress -= 5;
    } else if (focusScore < 40) {
      stress += 15;
    }

    // Many classes today adds stress
    final classCount = timetable.totalClassesToday;
    stress += (classCount * 3).toDouble();

    return stress.clamp(0, 100);
  }

  Color get stressColor {
    final s = stressLevel;
    if (s < 30) return const Color(0xFF00E676);
    if (s < 50) return const Color(0xFF76FF03);
    if (s < 70) return const Color(0xFFFFD93D);
    if (s < 85) return const Color(0xFFFF9800);
    return const Color(0xFFFF6B6B);
  }

  String get stressLabel {
    final s = stressLevel;
    if (s < 30) return 'Zen Mode 🧘';
    if (s < 50) return 'Doing Good 😊';
    if (s < 70) return 'Moderate 😐';
    if (s < 85) return 'Getting Hectic 😰';
    return 'Overload! 🔥';
  }

  void refresh() {
    notifyListeners();
  }
}
