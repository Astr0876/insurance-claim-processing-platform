import 'package:flutter/material.dart';

class AcademicDeadline {
  final String title;
  final DateTime date;
  final String source; // e.g., 'Gmail', 'Manual', 'Lumina Scan'
  final String keyword;

  AcademicDeadline({
    required this.title,
    required this.date,
    required this.source,
    this.keyword = '',
  });
}

enum StressState { green, yellow, red }

class CalendarService extends ChangeNotifier {
  List<AcademicDeadline> _deadlines = [];
  bool _isSyncing = false;

  List<AcademicDeadline> get deadlines => _deadlines;
  bool get isSyncing => _isSyncing;

  static const List<String> academicKeywords = [
    'Submission',
    'Deadline',
    'Exam',
    'Lab',
    'Viva',
    'Assignment',
    'Project',
    'Quiz',
  ];

  void loadDemoData() {
    final now = DateTime.now();
    _deadlines = [
      AcademicDeadline(
        title: 'OS Lab Viva',
        date: now.add(const Duration(days: 1)),
        source: 'Gmail',
        keyword: 'Viva',
      ),
      AcademicDeadline(
        title: 'DBMS Project Submission',
        date: now.add(const Duration(days: 3)),
        source: 'Gmail',
        keyword: 'Submission',
      ),
      AcademicDeadline(
        title: 'Mathematics III Quiz',
        date: now.add(const Duration(days: 1)),
        source: 'Manual',
        keyword: 'Quiz',
      ),
    ];
    notifyListeners();
  }

  Future<void> syncGmail() async {
    _isSyncing = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 3));

    final now = DateTime.now();
    // Simulate finding new deadlines in "emails"
    final newDeadlines = [
      AcademicDeadline(
        title: 'Data Structures Lab Submission',
        date: now.add(const Duration(days: 2)),
        source: 'Gmail',
        keyword: 'Submission',
      ),
      AcademicDeadline(
        title: 'Computer Networks Exam',
        date: now.add(const Duration(days: 7)),
        source: 'Gmail',
        keyword: 'Exam',
      ),
    ];

    for (var d in newDeadlines) {
      if (!_deadlines.any((existing) => existing.title == d.title)) {
        _deadlines.add(d);
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  StressState get stressState {
    if (_deadlines.isEmpty) return StressState.green;

    // Logic: if 3+ deadlines collide on a single day -> Red
    final Map<String, int> collisionMap = {};
    for (var d in _deadlines) {
      final dateKey = "${d.date.year}-${d.date.month}-${d.date.day}";
      collisionMap[dateKey] = (collisionMap[dateKey] ?? 0) + 1;
    }

    bool hasTripleCollision = collisionMap.values.any((count) => count >= 3);
    if (hasTripleCollision) return StressState.red;

    // Logic: if week is clear -> Green
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    bool hasDeadlinesThisWeek = _deadlines.any((d) => d.date.isBefore(nextWeek));
    
    if (!hasDeadlinesThisWeek) return StressState.green;

    return StressState.yellow;
  }

  // Map deadlines to a simple heatmap representation (0.0 to 1.0 intensity)
  Map<DateTime, double> get deadlineHeatmap {
    final Map<DateTime, double> heatmap = {};
    final Map<String, int> counts = {};
    
    for (var d in _deadlines) {
      final dateOnly = DateTime(d.date.year, d.date.month, d.date.day);
      counts[dateOnly.toString()] = (counts[dateOnly.toString()] ?? 0) + 1;
    }

    counts.forEach((dateStr, count) {
      final date = DateTime.parse(dateStr);
      // Intensity: 1-2 = 0.4, 3 = 0.7, 4+ = 1.0
      double intensity = 0.0;
      if (count >= 4) intensity = 1.0;
      else if (count == 3) intensity = 0.7;
      else if (count >= 1) intensity = 0.4;
      heatmap[date] = intensity;
    });

    return heatmap;
  }

  double get deadlineProximityScore {
    if (_deadlines.isEmpty) return 0;
    
    final now = DateTime.now();
    double totalProximity = 0;
    
    for (var d in _deadlines) {
      final diff = d.date.difference(now).inDays;
      if (diff < 0) continue; // Past deadline
      
      // Closer the deadline, higher the score
      // 0 days = 100 points, 7 days = 0 points
      if (diff <= 7) {
        totalProximity += (7 - diff) * 14.28; // Normalize to ~100
      }
    }
    
    return (totalProximity / (_deadlines.length.clamp(1, 10))).clamp(0, 100);
  }
}
