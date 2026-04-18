import 'dart:math';
import 'package:flutter/foundation.dart';

class FocusSession {
  final DateTime startTime;
  final DateTime endTime;
  final int appSwitches;
  final int distractions;
  final String label;

  FocusSession({
    required this.startTime,
    required this.endTime,
    required this.appSwitches,
    required this.distractions,
    required this.label,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  double get focusScore {
    // Base score starts at 100, deduct for distractions and app switches
    double score = 100;
    score -= (appSwitches * 2.5).clamp(0, 40);
    score -= (distractions * 5).clamp(0, 30);
    // Bonus for longer sessions
    if (durationMinutes > 45) score += 5;
    if (durationMinutes > 90) score += 5;
    return score.clamp(0, 100);
  }
}

class AppContext {
  final String appName;
  final DateTime timestamp;
  final bool isStudyApp;

  AppContext({
    required this.appName,
    required this.timestamp,
    required this.isStudyApp,
  });
}

class FocusService extends ChangeNotifier {
  final List<FocusSession> _sessions = [];
  final Random _rand = Random(42);

  // --- Context Switching & Cognitive Debt ---
  final List<AppContext> _contextHistory = [];
  double _cognitiveDebt = 0.0;
  static const double debtThreshold = 50.0;
  
  final Set<String> studyApps = {'Notion', 'VS Code', 'Obsidian', 'Lumina', 'Coursera'};
  final Set<String> distractionApps = {'Instagram', 'TikTok', 'Twitter', 'X', 'YouTube', 'Facebook'};

  double get cognitiveDebt => _cognitiveDebt;

  void recordAppSwitch(String appName) {
    final now = DateTime.now();
    final isStudy = studyApps.contains(appName);
    final isDistraction = distractionApps.contains(appName);

    // Exponential Decay: Debt decreases over time if no switches happen
    if (_contextHistory.isNotEmpty) {
      final lastSwitch = _contextHistory.last.timestamp;
      final diffSeconds = now.difference(lastSwitch).inSeconds;
      // Decay formula: Debt * e^(-k * t)
      _cognitiveDebt *= exp(-0.01 * diffSeconds);
    }

    // Penalize rapid switches, especially to distraction apps
    if (_contextHistory.isNotEmpty) {
      final lastSwitch = _contextHistory.last.timestamp;
      final interval = now.difference(lastSwitch).inSeconds;
      
      if (interval < 60) { // Rapid switch within a minute
        if (isDistraction) {
          _cognitiveDebt += 25.0 * (60 - interval) / 60;
        } else {
          _cognitiveDebt += 10.0 * (60 - interval) / 60;
        }
      }
    }

    _contextHistory.add(AppContext(
      appName: appName,
      timestamp: now,
      isStudyApp: isStudy,
    ));

    if (_cognitiveDebt > debtThreshold) {
      _triggerFocusAlert();
    }
    
    notifyListeners();
  }

  void _triggerFocusAlert() {
    // This will be listened to by AppState or AssistantService
    debugPrint('LUMINA ALERT: Focus Interruption! Cognitive Debt: ${_cognitiveDebt.toStringAsFixed(1)}');
  }

  // --- Legacy Focus Logic ---

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  void loadDemoData() {
    _sessions.clear();
    final now = DateTime.now();

    // Generate realistic demo sessions for today and past 6 days
    final labels = [
      'Data Structures Study',
      'OS Assignment',
      'CN Notes Review',
      'DBMS Practice',
      'Math Problem Set',
      'Project Work',
      'Reading',
      'Code Practice',
    ];

    for (int day = 6; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      // 2-4 sessions per day
      final sessionCount = 2 + _rand.nextInt(3);
      int hour = 8;

      for (int s = 0; s < sessionCount; s++) {
        hour += 1 + _rand.nextInt(3);
        if (hour > 22) break;
        final duration = 25 + _rand.nextInt(90); // 25-115 min
        final switches = _rand.nextInt(15);
        final distractions = _rand.nextInt(6);

        _sessions.add(FocusSession(
          startTime: DateTime(date.year, date.month, date.day, hour, _rand.nextInt(60)),
          endTime: DateTime(date.year, date.month, date.day, hour, _rand.nextInt(60))
              .add(Duration(minutes: duration)),
          appSwitches: switches,
          distractions: distractions,
          label: labels[_rand.nextInt(labels.length)],
        ));
      }
    }
  }

  List<FocusSession> get todaySessions {
    final now = DateTime.now();
    return _sessions.where((s) =>
      s.startTime.year == now.year &&
      s.startTime.month == now.month &&
      s.startTime.day == now.day
    ).toList();
  }

  double get todayFocusScore {
    final today = todaySessions;
    if (today.isEmpty) return 0;
    return today.map((s) => s.focusScore).reduce((a, b) => a + b) / today.length;
  }

  int get todayStudyMinutes {
    return todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  int get todayAppSwitches {
    return todaySessions.fold<int>(0, (sum, s) => sum + s.appSwitches);
  }

  int get todayDistractions {
    return todaySessions.fold<int>(0, (sum, s) => sum + s.distractions);
  }

  double get weeklyAverageFocusScore {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.focusScore).reduce((a, b) => a + b) / _sessions.length;
  }

  int get totalStudyMinutesWeek {
    return _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Daily focus scores for the past 7 days
  List<MapEntry<String, double>> get weeklyScores {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <MapEntry<String, double>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final daySessions = _sessions.where((s) =>
        s.startTime.year == date.year &&
        s.startTime.month == date.month &&
        s.startTime.day == date.day
      ).toList();

      final avg = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.focusScore).reduce((a, b) => a + b) / daySessions.length;

      result.add(MapEntry(days[date.weekday - 1], avg));
    }
    return result;
  }

  /// Daily study minutes for the past 7 days
  List<MapEntry<String, int>> get weeklyMinutes {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <MapEntry<String, int>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final daySessions = _sessions.where((s) =>
        s.startTime.year == date.year &&
        s.startTime.month == date.month &&
        s.startTime.day == date.day
      ).toList();

      final total = daySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      result.add(MapEntry(days[date.weekday - 1], total));
    }
    return result;
  }
}
