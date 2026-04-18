import '../utils/constants.dart';

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
    if (percentage >= target) return 0;
    // Solve: (attended + x) / (total + x) >= target/100
    // attended + x >= (target/100) * (total + x)
    // attended + x >= target*total/100 + target*x/100
    // x * (1 - target/100) >= target*total/100 - attended
    // x >= (target*total/100 - attended) / (1 - target/100)
    final needed = ((target * total / 100) - attended) / (1 - target / 100);
    return needed.ceil().clamp(0, 999);
  }

  /// How many classes can be bunked and stay at/above target
  int safeBunks({double target = 75.0}) {
    if (percentage < target) return 0;
    // Solve: attended / (total + x) >= target/100
    // attended * 100 >= target * (total + x)
    // attended * 100 / target - total >= x
    final canBunk = (attended * 100 / target) - total;
    return canBunk.floor().clamp(0, 999);
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
      return '🟠 Attend next $needed class${needed == 1 ? '' : 'es'} to recover!';
    }
    final needed = classesToReachTarget();
    return '🔴 Critical! Attend $needed classes immediately!';
  }
}

class AttendanceService {
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
    // Overall safe bunks based on aggregate
    final totalAttended = _records.values.fold<int>(0, (s, r) => s + r.attended);
    final totalClasses = _records.values.fold<int>(0, (s, r) => s + r.total);
    if (totalClasses == 0) return 0;
    final canBunk = (totalAttended * 100 / 75) - totalClasses;
    return canBunk.floor().clamp(0, 999);
  }

  int get classesToRecover {
    final totalAttended = _records.values.fold<int>(0, (s, r) => s + r.attended);
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
      _records[subject] = AttendanceRecord(subject: subject, attended: 0, total: 0);
    }
  }
}
