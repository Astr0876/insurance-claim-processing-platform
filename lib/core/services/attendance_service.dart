import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AttendanceAnalytics {
  final double currentPercentage;
  final int classesNeeded;
  final int bunkBudget;

  const AttendanceAnalytics({
    required this.currentPercentage,
    required this.classesNeeded,
    required this.bunkBudget,
  });

  bool get isAtRisk => currentPercentage < 75;
}

class AttendanceRecord {
  final String subject;
  int attended;
  int total;

  AttendanceRecord({
    required this.subject,
    required this.attended,
    required this.total,
  });

  double get percentage => total == 0 ? 100.0 : (attended / total) * 100;

  /// Classes needed to reach target attendance
  int classesToReachTarget({double target = 75.0}) {
    if (target <= 0 || target >= 100) return 0;
    if (percentage >= target) return 0;
    final needed = ((target * total / 100) - attended) / (1 - target / 100);
    return needed.ceil().clamp(0, 999);
  }

  /// How many classes can be bunked and stay at/above target
  int safeBunks({double target = 75.0}) {
    if (target <= 0 || target >= 100) return 0;
    
    // STRICT USER FORMULA: (Total Classes - (Total Classes * 0.75)) - Classes Already Missed
    // This simplifies to: Attended - (target/100 * Total)
    final double targetRatio = target / 100.0;
    final int missed = total - attended;
    final double allowedMisses = total * (1.0 - targetRatio);
    final double bunkBudget = allowedMisses - missed;
    
    return bunkBudget.floor().clamp(0, 999);
  }

  String get statusMessage {
    final pct = percentage;
    if (pct >= 85) return '🟢 You\'re cruising! Safe to relax.';
    if (pct >= 75) {
      final bunks = safeBunks();
      return '🟡 Safe zone. You can bunk $bunks class${bunks == 1 ? '' : 'es'}.';
    }
    if (pct >= 60) {
      final needed = classesToReachTarget();
      return '🟠 Classes to Recover: $needed. Attend next consecutive classes!';
    }
    final needed = classesToReachTarget();
    return '🔴 Critical! Classes to Recover: $needed. Attend immediately!';
  }
}

class AttendanceService extends ChangeNotifier {
  Map<String, AttendanceRecord> _records = {};

  Map<String, AttendanceRecord> get records => _records;

  void loadDemoData() {
    _records = {};
    AppConstants.demoAttendance.forEach((subject, data) {
      _records[subject] = AttendanceRecord(
        subject: subject,
        attended: data['attended']!,
        total: data['total']!,
      );
    });
  }

  double get overallPercentage {
    if (_records.isEmpty) return 100.0;
    int totalAttended = 0;
    int totalClasses = 0;
    for (final r in _records.values) {
      totalAttended += r.attended;
      totalClasses += r.total;
    }
    return totalClasses == 0 ? 100.0 : (totalAttended / totalClasses) * 100;
  }

  int get totalSafeBunks {
    final totalAttended = _records.values.fold<int>(
      0,
      (s, r) => s + r.attended,
    );
    final totalClasses = _records.values.fold<int>(0, (s, r) => s + r.total);
    if (totalClasses == 0) return 0;
    
    // STRICT USER FORMULA
    final double allowedMisses = totalClasses * 0.25;
    final int missed = totalClasses - totalAttended;
    final double bunkBudget = allowedMisses - missed;
    
    return bunkBudget.floor().clamp(0, 999);
  }

  int get classesToRecover {
    final totalAttended = _records.values.fold<int>(
      0,
      (s, r) => s + r.attended,
    );
    final totalClasses = _records.values.fold<int>(0, (s, r) => s + r.total);
    if (totalClasses == 0) return 0;
    final pct = (totalAttended / totalClasses) * 100;
    if (pct >= 75) return 0;
    final needed = ((75 * totalClasses / 100) - totalAttended) / (1 - 75 / 100);
    return needed.ceil().clamp(0, 999);
  }

  void markAttended(String subject) {
    if (_records.containsKey(subject)) {
      _records[subject]!.attended++;
      _records[subject]!.total++;
    }
  }

  void markAbsent(String subject) {
    if (_records.containsKey(subject)) {
      _records[subject]!.total++;
    }
  }

  void addSubject(String subject) {
    if (!_records.containsKey(subject)) {
      _records[subject] = AttendanceRecord(
        subject: subject,
        attended: 0,
        total: 0,
      );
    }
  }

  void syncSubjects(Iterable<String> subjects) {
    for (final subject in subjects) {
      addSubject(subject);
    }
  }

  AttendanceAnalytics analyticsForSubject(
    String subject, {
    double target = AppConstants.attendanceThreshold,
  }) {
    final record =
        _records[subject] ??
        AttendanceRecord(subject: subject, attended: 0, total: 0);
    return AttendanceAnalytics(
      currentPercentage: record.percentage,
      classesNeeded: record.classesToReachTarget(target: target),
      bunkBudget: record.safeBunks(target: target),
    );
  }

  AttendanceAnalytics get overallAnalytics {
    return AttendanceAnalytics(
      currentPercentage: overallPercentage,
      classesNeeded: classesToRecover,
      bunkBudget: totalSafeBunks,
    );
  }
}
