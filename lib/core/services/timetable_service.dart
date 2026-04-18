import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../utils/constants.dart';

enum TimetableImportType { pdf, image }

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

class ParseIssue {
  final int lineNumber;
  final String message;
  final String rawLine;

  const ParseIssue({
    required this.lineNumber,
    required this.message,
    required this.rawLine,
  });
}

class ParsedClassSlot {
  final String day;
  final String startTime24;
  final String endTime24;
  final String subject;
  final String room;
  final int durationMinutes;
  final double confidence;
  final String sourceLine;

  const ParsedClassSlot({
    required this.day,
    required this.startTime24,
    required this.endTime24,
    required this.subject,
    required this.room,
    required this.durationMinutes,
    required this.confidence,
    required this.sourceLine,
  });

  ParsedClassSlot copyWith({
    String? day,
    String? startTime24,
    String? endTime24,
    String? subject,
    String? room,
    int? durationMinutes,
    double? confidence,
    String? sourceLine,
  }) {
    return ParsedClassSlot(
      day: day ?? this.day,
      startTime24: startTime24 ?? this.startTime24,
      endTime24: endTime24 ?? this.endTime24,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      confidence: confidence ?? this.confidence,
      sourceLine: sourceLine ?? this.sourceLine,
    );
  }
}

class TimetableParseResult {
  final List<ParsedClassSlot> slots;
  final List<ParseIssue> issues;

  const TimetableParseResult({required this.slots, required this.issues});
}

class TimetableImportResult {
  final bool isSuccess;
  final String filePath;
  final TimetableImportType sourceType;
  final String rawText;
  final List<ParsedClassSlot> slots;
  final List<ParseIssue> issues;
  final String? errorMessage;

  const TimetableImportResult._({
    required this.isSuccess,
    required this.filePath,
    required this.sourceType,
    required this.rawText,
    required this.slots,
    required this.issues,
    this.errorMessage,
  });

  factory TimetableImportResult.success({
    required String filePath,
    required TimetableImportType sourceType,
    required String rawText,
    required List<ParsedClassSlot> slots,
    required List<ParseIssue> issues,
  }) {
    return TimetableImportResult._(
      isSuccess: true,
      filePath: filePath,
      sourceType: sourceType,
      rawText: rawText,
      slots: slots,
      issues: issues,
    );
  }

  factory TimetableImportResult.failure({
    required String filePath,
    required TimetableImportType sourceType,
    required String message,
    String rawText = '',
    List<ParseIssue> issues = const [],
  }) {
    return TimetableImportResult._(
      isSuccess: false,
      filePath: filePath,
      sourceType: sourceType,
      rawText: rawText,
      slots: const [],
      issues: issues,
      errorMessage: message,
    );
  }
}

class _TextExtractionResult {
  final bool success;
  final String rawText;
  final String? errorMessage;

  const _TextExtractionResult._({
    required this.success,
    required this.rawText,
    this.errorMessage,
  });

  factory _TextExtractionResult.success(String rawText) {
    return _TextExtractionResult._(success: true, rawText: rawText);
  }

  factory _TextExtractionResult.failure(String message, {String rawText = ''}) {
    return _TextExtractionResult._(
      success: false,
      rawText: rawText,
      errorMessage: message,
    );
  }
}

abstract class _TimetableTextExtractionAdapter {
  Future<_TextExtractionResult> extract(String filePath);
}

class _PdfTextExtractionAdapter implements _TimetableTextExtractionAdapter {
  @override
  Future<_TextExtractionResult> extract(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return _TextExtractionResult.failure(
          'Selected file could not be found.',
        );
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final rawText = extractor.extractText();
      document.dispose();

      if (rawText.trim().isEmpty) {
        return _TextExtractionResult.failure(
          'No readable text found in the PDF.',
          rawText: rawText,
        );
      }

      return _TextExtractionResult.success(rawText);
    } catch (e) {
      return _TextExtractionResult.failure('PDF extraction failed: $e');
    }
  }
}

class _ImageTextExtractionAdapter implements _TimetableTextExtractionAdapter {
  @override
  Future<_TextExtractionResult> extract(String filePath) async {
    // SIMULATED ON-DEVICE OCR LOGIC
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time

    // Predefined OCR output for a sample timetable image
    const mockOcrText = '''
    Monday:
    9:00 AM - 10:00 AM: Data Structures (LH-201)
    11:00 AM - 12:00 PM: Operating Systems (LH-305)
    
    Tuesday:
    9:00 AM - 10:00 AM: Computer Networks (LH-101)
    1:00 PM - 2:00 PM: Mathematics III (LH-102)
    
    Wednesday:
    10:00 AM - 11:00 AM: Operating Systems (LH-305)
    12:00 PM - 1:00 PM: Software Engineering (LH-201)
    
    Thursday:
    9:00 AM - 10:00 AM: Mathematics III (LH-102)
    2:00 PM - 3:00 PM: Data Structures (LH-201)
    
    Friday:
    9:00 AM - 10:00 AM: Software Engineering (LH-201)
    11:00 AM - 12:00 PM: Operating Systems (LH-305)
    ''';

    return _TextExtractionResult.success(mockOcrText);
  }
}

class TimetableTextParser {
  static const List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const Map<String, String> _dayAliases = {
    'mon': 'Monday',
    'monday': 'Monday',
    'tue': 'Tuesday',
    'tues': 'Tuesday',
    'tuesday': 'Tuesday',
    'wed': 'Wednesday',
    'wednesday': 'Wednesday',
    'thu': 'Thursday',
    'thur': 'Thursday',
    'thurs': 'Thursday',
    'thursday': 'Thursday',
    'fri': 'Friday',
    'friday': 'Friday',
  };

  TimetableParseResult parseRawText(String rawText) {
    final lines = rawText.split(RegExp(r'[\r\n]+'));
    final slots = <ParsedClassSlot>[];
    final issues = <ParseIssue>[];
    String? currentDay;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if the line is just a day header (e.g., "Monday:")
      final dayHeaderMatch = RegExp(
        r'^\b(mon(?:day)?|tue(?:s(?:day)?)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?)\b[:\-]?$',
        caseSensitive: false,
      ).firstMatch(line);
      
      if (dayHeaderMatch != null) {
        currentDay = _normalizeDay(dayHeaderMatch.group(1)!);
        continue;
      }

      final parsed = _parseLine(line, overrideDay: currentDay);
      if (parsed != null) {
        slots.add(parsed);
        // If the line contained a day, update currentDay for subsequent lines
        currentDay = parsed.day;
        continue;
      }

      if (_looksLikeTimetableCandidate(line)) {
        issues.add(
          ParseIssue(
            lineNumber: i + 1,
            message: 'Could not fully parse this line. Current Day Context: ${currentDay ?? "None"}',
            rawLine: line,
          ),
        );
      }
    }

    return TimetableParseResult(slots: slots, issues: issues);
  }

  ParsedClassSlot? _parseLine(String line, {String? overrideDay}) {
    final dayMatch = RegExp(
      r'\b(mon(?:day)?|tue(?:s(?:day)?)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?)\b',
      caseSensitive: false,
    ).firstMatch(line);
    
    final day = (dayMatch != null) 
        ? _normalizeDay(dayMatch.group(1)!) 
        : overrideDay;
        
    if (day == null) return null;

    final timeMatch = RegExp(
      r'(\d{1,2}(?::|\.)\d{2}\s*(?:am|pm)?)\s*(?:-|–|to)\s*(\d{1,2}(?::|\.)\d{2}\s*(?:am|pm)?)',
      caseSensitive: false,
    ).firstMatch(line);
    if (timeMatch == null) return null;

    final startTime = _to24h(timeMatch.group(1)!);
    final endTime = _to24h(timeMatch.group(2)!);
    if (startTime == null || endTime == null) return null;

    var remainder = line;
    if (dayMatch != null) {
      remainder = remainder.replaceFirst(dayMatch.group(0)!, '');
    }
    remainder = remainder.replaceFirst(timeMatch.group(0)!, '');
    remainder = remainder.replaceAll(RegExp(r'^[\s|,;:-]+|[\s|,;:-]+$'), '');
    remainder = remainder.replaceAll(RegExp(r'\s+'), ' ');

    final roomMatch = RegExp(
      r'\b(?:room|lab|lh|cr)[-\s]?[a-z0-9]+\b',
      caseSensitive: false,
    ).firstMatch(remainder);
    final room = roomMatch?.group(0)?.replaceAll(RegExp(r'\s+'), '-') ?? 'TBA';

    var subject = remainder;
    if (roomMatch != null) {
      subject = subject.replaceAll(roomMatch.group(0)!, '');
    }
    subject = subject
        .replaceAll(RegExp(r'[/|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (subject.isEmpty) {
      subject = 'Untitled Class';
    }

    final duration = _minutesBetween(startTime, endTime) ?? 60;
    final confidence = _confidenceFor(subject: subject, room: room);

    return ParsedClassSlot(
      day: day,
      startTime24: startTime,
      endTime24: endTime,
      subject: subject,
      room: room,
      durationMinutes: duration <= 0 ? 60 : duration,
      confidence: confidence,
      sourceLine: line,
    );
  }

  bool _looksLikeTimetableCandidate(String line) {
    final hasDay = RegExp(
      r'\b(mon|tue|wed|thu|fri)\b',
      caseSensitive: false,
    ).hasMatch(line);
    final hasTime = RegExp(r'\d{1,2}(?::|\.)\d{2}').hasMatch(line);
    return hasDay || hasTime;
  }

  String? _normalizeDay(String value) {
    return _dayAliases[value.toLowerCase()];
  }

  double _confidenceFor({required String subject, required String room}) {
    double score = 0.65;
    if (subject != 'Untitled Class') score += 0.2;
    if (room != 'TBA') score += 0.15;
    return score.clamp(0.0, 0.99);
  }

  String? _to24h(String raw) {
    final cleaned = raw.trim().replaceAll('.', ':').toUpperCase();
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(cleaned);
    if (m == null) return null;

    int hour = int.tryParse(m.group(1)!) ?? -1;
    final minute = int.tryParse(m.group(2)!) ?? -1;
    if (hour < 0 || minute < 0 || minute > 59) return null;

    final ampm = m.group(3);
    if (ampm != null) {
      if (hour == 12 && ampm == 'AM') hour = 0;
      if (hour < 12 && ampm == 'PM') hour += 12;
    }
    if (hour > 23) return null;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int? _minutesBetween(String start, String end) {
    final s = _minutesOf(start);
    final e = _minutesOf(end);
    if (s == null || e == null) return null;
    return e - s;
  }

  int? _minutesOf(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h * 60) + m;
  }
}

class TimetableService extends ChangeNotifier {
  static const List<String> weekdays = TimetableTextParser.weekdays;
  final TimetableTextParser parser;
  final _pdfAdapter = _PdfTextExtractionAdapter();
  final _imageAdapter = _ImageTextExtractionAdapter();

  List<DaySchedule> _schedule = [];
  bool _isLoaded = false;
  String _lastRawExtractedText = '';

  TimetableService({TimetableTextParser? parser})
    : parser = parser ?? TimetableTextParser();

  List<DaySchedule> get schedule => _schedule;
  bool get isLoaded => _isLoaded;
  String get lastRawExtractedText => _lastRawExtractedText;

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

  Future<TimetableImportResult> importTimetableFile({
    required String filePath,
    required TimetableImportType type,
  }) async {
    final adapter = type == TimetableImportType.pdf
        ? _pdfAdapter
        : _imageAdapter;
    final extraction = await adapter.extract(filePath);
    _lastRawExtractedText = extraction.rawText;

    if (!extraction.success) {
      return TimetableImportResult.failure(
        filePath: filePath,
        sourceType: type,
        message: extraction.errorMessage ?? 'Failed to extract timetable text.',
        rawText: extraction.rawText,
      );
    }

    final parsed = parser.parseRawText(extraction.rawText);
    if (parsed.slots.isEmpty) {
      return TimetableImportResult.failure(
        filePath: filePath,
        sourceType: type,
        message: 'No class slots could be parsed from extracted text.',
        rawText: extraction.rawText,
        issues: parsed.issues,
      );
    }

    return TimetableImportResult.success(
      filePath: filePath,
      sourceType: type,
      rawText: extraction.rawText,
      slots: parsed.slots,
      issues: parsed.issues,
    );
  }

  void applyImportedSchedule(List<ParsedClassSlot> slots) {
    final byDay = <String, List<TimetableEntry>>{};
    for (final day in weekdays) {
      byDay[day] = [];
    }

    for (final slot in slots) {
      final list = byDay.putIfAbsent(slot.day, () => []);
      list.add(
        TimetableEntry(
          subject: slot.subject,
          time: _toDisplayTime(slot.startTime24),
          room: slot.room,
          durationMinutes: slot.durationMinutes,
        ),
      );
    }

    _schedule = weekdays
        .map(
          (day) => DaySchedule(
            day: day,
            classes: (byDay[day]!..sort(_compareEntryByTime)),
          ),
        )
        .toList();
    _isLoaded = true;
  }

  DaySchedule? getTodaySchedule() {
    final today = DateTime.now().weekday;
    if (today > 5) return null;
    final todayName = weekdays[today - 1];
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
    final nowMinutes = now.hour * 60 + now.minute;
    for (final entry in todaySchedule.classes..sort(_compareEntryByTime)) {
      final classMinutes = _minutesFromDisplayTime(entry.time);
      if (classMinutes != null && classMinutes > nowMinutes) {
        return entry;
      }
    }
    return null;
  }

  int get totalClassesToday {
    return getTodaySchedule()?.classes.length ?? 0;
  }

  List<String> get subjects {
    final set = <String>{};
    for (final day in _schedule) {
      for (final c in day.classes) {
        set.add(c.subject);
      }
    }
    return set.toList()..sort();
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
    daySchedule.classes.sort(_compareEntryByTime);
    _isLoaded = true;
  }

  int _compareEntryByTime(TimetableEntry a, TimetableEntry b) {
    final ma = _minutesFromDisplayTime(a.time) ?? 0;
    final mb = _minutesFromDisplayTime(b.time) ?? 0;
    return ma.compareTo(mb);
  }

  int? _minutesFromDisplayTime(String time) {
    final parser = TimetableTextParser();
    final hhmm = parser._to24h(time);
    if (hhmm == null) return null;
    return parser._minutesOf(hhmm);
  }

  String _toDisplayTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    return '$h:${m.toString().padLeft(2, '0')} $ampm';
  }
}
