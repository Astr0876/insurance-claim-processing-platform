import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'label': label,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'app_switches': appSwitches,
      'distractions': distractions,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      appSwitches: json['app_switches'] ?? 0,
      distractions: json['distractions'] ?? 0,
      label: json['label'] ?? 'Focus Session',
    );
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

  // --- Session Tracking ---
  bool _isTracking = false;
  DateTime? _sessionStartTime;
  int _currentAppSwitches = 0;
  int _currentDistractions = 0;
  String _currentLabel = 'New Session';

  bool get isTracking => _isTracking;
  int get currentAppSwitches => _currentAppSwitches;
  int get currentDistractions => _currentDistractions;

  // --- Context Switching & Cognitive Debt ---
  final List<AppContext> _contextHistory = [];
  double _cognitiveDebt = 0.0;
  static const double debtThreshold = 50.0;
  
  final Set<String> studyApps = {'Notion', 'VS Code', 'Obsidian', 'Lumina', 'Coursera'};
  final Set<String> distractionApps = {'Instagram', 'TikTok', 'Twitter', 'X', 'YouTube', 'Facebook'};

  double get cognitiveDebt => _cognitiveDebt;

  void startSession({String label = 'Deep Work'}) {
    _isTracking = true;
    _sessionStartTime = DateTime.now();
    _currentAppSwitches = 0;
    _currentDistractions = 0;
    _currentLabel = label;
    notifyListeners();
  }

  Future<void> endSession() async {
    if (!_isTracking || _sessionStartTime == null) return;

    final endTime = DateTime.now();
    final session = FocusSession(
      startTime: _sessionStartTime!,
      endTime: endTime,
      appSwitches: _currentAppSwitches,
      distractions: _currentDistractions,
      label: _currentLabel,
    );

    _sessions.add(session);
    _isTracking = false;
    _sessionStartTime = null;

    // --- Supabase Insertion ---
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('focus_sessions').insert(session.toJson(user.id));
        debugPrint('Focus session saved to Supabase');
        
        // Fetch last 7 days of sessions to compute Cognitive Debt Score
        await computeCognitiveDebtFromHistory();
      }
    } catch (e) {
      debugPrint('Error saving focus session to Supabase: $e');
    }

    notifyListeners();
  }

  Future<void> fetchSessions() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('focus_sessions')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: false);

      if (response.isNotEmpty) {
        _sessions.clear();
        for (var row in response) {
          _sessions.add(FocusSession.fromJson(row));
        }
        debugPrint('Fetched ${_sessions.length} focus sessions from Supabase');
        
        await computeCognitiveDebtFromHistory();
      }
    } catch (e) {
      debugPrint('Error fetching focus sessions: $e');
    }
    notifyListeners();
  }

  Future<void> computeCognitiveDebtFromHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final lastWeek = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      final response = await supabase
          .from('focus_sessions')
          .select()
          .eq('user_id', user.id)
          .gte('start_time', lastWeek);

      if (response.isNotEmpty) {
        int totalSwitches = 0;
        int totalDistractions = 0;
        int count = response.length;

        for (var row in response) {
          totalSwitches += (row['app_switches'] as int? ?? 0);
          totalDistractions += (row['distractions'] as int? ?? 0);
        }

        // Formula for Cognitive Debt Score: 
        // Average switches and distractions per session, weighted
        // (Avg Switches * 0.5) + (Avg Distractions * 2.0)
        final avgSwitches = totalSwitches / count;
        final avgDistractions = totalDistractions / count;
        
        _cognitiveDebt = (avgSwitches * 0.5) + (avgDistractions * 2.0);
        // Normalize to some extent, e.g., max 100
        _cognitiveDebt = _cognitiveDebt.clamp(0, 100);
        
        debugPrint('Computed Cognitive Debt Score from history: ${_cognitiveDebt.toStringAsFixed(1)}');
      } else {
        _cognitiveDebt = 0.0;
      }
    } catch (e) {
      debugPrint('Error computing cognitive debt from history: $e');
    }
    notifyListeners();
  }

  void recordAppSwitch(String appName) {
    final now = DateTime.now();
    final isStudy = studyApps.contains(appName);
    final isDistraction = distractionApps.contains(appName);

    // Track for current session
    if (_isTracking) {
      _currentAppSwitches++;
      if (isDistraction) {
        _currentDistractions++;
      }
    }

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
