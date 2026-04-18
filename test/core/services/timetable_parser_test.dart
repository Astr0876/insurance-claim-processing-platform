import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/timetable_service.dart';

void main() {
  group('TimetableTextParser', () {
    test('parses valid timetable rows', () {
      const raw = '''
Monday 9:00 AM - 10:00 AM Data Structures LH-201
Tue 11:00 AM - 12:00 PM Operating Systems Room-305
''';
      final parser = TimetableTextParser();
      final result = parser.parseRawText(raw);

      expect(result.slots.length, 2);
      expect(result.slots.first.day, 'Monday');
      expect(result.slots.first.startTime24, '09:00');
      expect(result.slots.first.durationMinutes, 60);
    });

    test('keeps valid rows and reports malformed candidates', () {
      const raw = '''
Wednesday 10:00 AM - 11:00 AM Software Engineering LH-201
Thu no-time malformed row
''';
      final parser = TimetableTextParser();
      final result = parser.parseRawText(raw);

      expect(result.slots.length, 1);
      expect(result.issues, isNotEmpty);
    });

    test('ignores non-timetable text', () {
      const raw = '''
Welcome to the semester handbook.
Use this document to prepare for exams.
''';
      final parser = TimetableTextParser();
      final result = parser.parseRawText(raw);

      expect(result.slots, isEmpty);
      expect(result.issues, isEmpty);
    });
  });
}
