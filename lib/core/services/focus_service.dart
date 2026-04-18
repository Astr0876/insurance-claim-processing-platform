import 'dart:math';

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

class FocusService {
  final List<FocusSession> _sessions = [];
  final Random _rand = Random(42);

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
