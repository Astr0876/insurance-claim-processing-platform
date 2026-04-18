import '../utils/constants.dart';

class TimetableEntry {
  final String subject;
  final String time;
  final String room;
  final int durationMinutes;

  TimetableEntry({
    required this.subject,
    required this.time,
    required this.room,
    required this.durationMinutes,
  });
}

class DaySchedule {
  final String day;
  final List<TimetableEntry> classes;

  DaySchedule({required this.day, required this.classes});
}

class TimetableService {
  List<DaySchedule> _schedule = [];
  bool _isLoaded = false;

  List<DaySchedule> get schedule => _schedule;
  bool get isLoaded => _isLoaded;

  void loadDemoData() {
    _schedule = AppConstants.demoTimetable.map((dayData) {
      return DaySchedule(
        day: dayData['day'] as String,
        classes: (dayData['classes'] as List).map((c) {
          final classMap = c as Map<String, dynamic>;
          return TimetableEntry(
            subject: classMap['subject'] as String,
            time: classMap['time'] as String,
            room: classMap['room'] as String,
            durationMinutes: classMap['duration'] as int,
          );
        }).toList(),
      );
    }).toList();
    _isLoaded = true;
  }

  DaySchedule? getTodaySchedule() {
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    if (today > 5) return null; // Weekend
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final todayName = days[today - 1];
    try {
      return _schedule.firstWhere((s) => s.day == todayName);
    } catch (_) {
      return null;
    }
  }

  TimetableEntry? getNextClass() {
    final todaySchedule = getTodaySchedule();
    if (todaySchedule == null) return null;

    final now = DateTime.now();
    for (final entry in todaySchedule.classes) {
      // Parse time like "9:00 AM"
      final parts = entry.time.split(RegExp(r'[: ]'));
      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final ampm = parts.length > 2 ? parts[2].toUpperCase() : 'AM';

      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      final classTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (classTime.isAfter(now)) {
        return entry;
      }
    }
    return null;
  }

  int get totalClassesToday {
    return getTodaySchedule()?.classes.length ?? 0;
  }

  void addManualEntry(String day, TimetableEntry entry) {
    final daySchedule = _schedule.firstWhere(
      (s) => s.day == day,
      orElse: () {
        final newDay = DaySchedule(day: day, classes: []);
        _schedule.add(newDay);
        return newDay;
      },
    );
    daySchedule.classes.add(entry);
    _isLoaded = true;
  }
}
