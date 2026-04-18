import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, AttendanceRecord> _records = {};

  Map<String, AttendanceRecord> get records => _records;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> fetchRecords() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId);

      _records = {
        for (final item in response)
          item['subject'] as String: AttendanceRecord(
            subject: item['subject'] as String,
            attended: item['attended_count'] as int,
            total: item['total_count'] as int,
          )
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching attendance records: $e');
    }
  }

  void loadDemoData() {
    _records = {};
    AppConstants.demoAttendance.forEach((subject, data) {
      _records[subject] = AttendanceRecord(
        subject: subject,
        attended: data['attended']!,
        total: data['total']!,
      );
    });
    notifyListeners();
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

  Future<void> markAttended(String subject) async {
    final userId = _userId;
    if (userId == null) return;

    if (_records.containsKey(subject)) {
      final record = _records[subject]!;
      final newAttended = record.attended + 1;
      final newTotal = record.total + 1;

      try {
        await _supabase
            .from('attendance')
            .update({
              'attended_count': newAttended,
              'total_count': newTotal,
            })
            .match({'user_id': userId, 'subject': subject});

        record.attended = newAttended;
        record.total = newTotal;
        notifyListeners();
      } catch (e) {
        debugPrint('Error marking attended: $e');
      }
    }
  }

  Future<void> markAbsent(String subject) async {
    final userId = _userId;
    if (userId == null) return;

    if (_records.containsKey(subject)) {
      final record = _records[subject]!;
      final newTotal = record.total + 1;

      try {
        await _supabase
            .from('attendance')
            .update({
              'total_count': newTotal,
            })
            .match({'user_id': userId, 'subject': subject});

        record.total = newTotal;
        notifyListeners();
      } catch (e) {
        debugPrint('Error marking absent: $e');
      }
    }
  }

  Future<void> addSubject(String subject) async {
    final userId = _userId;
    if (userId == null) return;

    if (!_records.containsKey(subject)) {
      try {
        await _supabase.from('attendance').upsert({
          'user_id': userId,
          'subject': subject,
          'attended_count': 0,
          'total_count': 0,
        });

        _records[subject] = AttendanceRecord(
          subject: subject,
          attended: 0,
          total: 0,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error adding subject: $e');
      }
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
