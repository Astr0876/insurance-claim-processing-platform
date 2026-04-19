import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/constants.dart';
import 'gemini_service.dart';
import 'gradio_service.dart';

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
  final Map<String, dynamic>? fullJson;

  const TimetableImportResult._({
    required this.isSuccess,
    required this.filePath,
    required this.sourceType,
    required this.rawText,
    required this.slots,
    required this.issues,
    this.errorMessage,
    this.fullJson,
  });

  factory TimetableImportResult.success({
    required String filePath,
    required TimetableImportType sourceType,
    required String rawText,
    required List<ParsedClassSlot> slots,
    required List<ParseIssue> issues,
    Map<String, dynamic>? fullJson,
  }) {
    return TimetableImportResult._(
      isSuccess: true,
      filePath: filePath,
      sourceType: sourceType,
      rawText: rawText,
      slots: slots,
      issues: issues,
      fullJson: fullJson,
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

  static const Map<String, String> _facultyMap = {
    "KKD": "Dr. Kailas Devadkar",
    "NR": "Dr. Nataasha Raul",
    "JS": "Prof. J. Sharma",
    "RS": "Prof. R. Singh",
    "PM": "Prof. P. Mehta",
    "SK": "Prof. S. Kumar",
    "AD": "Prof. A. Desai",
    "MG": "Prof. M. Gupta",
    "VR": "Prof. V. Rao",
    "SP": "Prof. S. Patil",
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

    // --- Backend Port: Subject/Faculty Pattern ---
    final entryMatch = RegExp(
      r'\b([A-Z]{2,})\s*/\s*([A-Z])?\s*/?\s*([A-Z]{2,})\b',
    ).firstMatch(remainder);

    String subject;
    if (entryMatch != null) {
      final subCode = entryMatch.group(1)!;
      final facCode = entryMatch.group(3)!;
      final faculty = _facultyMap[facCode] ?? facCode;
      subject = '$subCode ($faculty)';
    } else {
      subject = remainder;
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
  final GradioService _gradioService = GradioService();

  List<DaySchedule> _schedule = [];
  bool _isLoaded = false;
  String _lastRawExtractedText = '';

  TimetableService({TimetableTextParser? parser})
    : parser = parser ?? TimetableTextParser();

  List<DaySchedule> get schedule => _schedule;
  bool get isLoaded => _isLoaded;
  String get lastRawExtractedText => _lastRawExtractedText;

  Future<void> fetchTimetable() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _isLoaded = false;
      notifyListeners();
      return;
    }

    try {
      final response = await client
          .from('timetable_entries')
          .select()
          .eq('user_id', user.id);

      final List<ParsedClassSlot> slots = [];
      for (final row in response as List<dynamic>) {
        final startTime12 = row['start_time'] as String;
        final duration = row['duration_minutes'] as int? ?? 60;
        final startTime24 = parser._to24h(startTime12) ?? '00:00';
        
        final startMins = parser._minutesOf(startTime24) ?? 0;
        final endMins = startMins + duration;
        final endH = (endMins ~/ 60) % 24;
        final endM = endMins % 60;
        final endTime24 = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

        slots.add(ParsedClassSlot(
          day: row['day'] as String,
          startTime24: startTime24,
          endTime24: endTime24,
          subject: row['subject'] as String,
          room: row['room'] as String? ?? 'TBA',
          durationMinutes: duration,
          confidence: 1.0,
          sourceLine: 'Database entry',
        ));
      }

      applyImportedSchedule(slots);
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      _isLoaded = false;
      notifyListeners();
    }
  }

  Future<TimetableImportResult> importTimetableFile({
    required String filePath,
    required TimetableImportType type,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return TimetableImportResult.failure(
          filePath: filePath,
          sourceType: type,
          message: 'Selected file could not be found.',
        );
      }

      String rawText = '';
      
      // STEP 1: Extract raw text from the file
      if (type == TimetableImportType.pdf) {
        debugPrint('LUMINA: Extracting text from PDF...');
        rawText = await _extractTextFromPdf(file);
      } else {
        debugPrint('LUMINA: Extracting text from image via OCR...');
        rawText = await _extractTextFromImage(file);
      }

      if (rawText.trim().isEmpty) {
        return TimetableImportResult.failure(
          filePath: filePath,
          sourceType: type,
          message: 'Could not extract any text from this file. Try a clearer image or a text-based PDF.',
        );
      }

      _lastRawExtractedText = rawText;
      debugPrint('LUMINA: Extracted ${rawText.length} chars. Sending to AI for parsing...');

      // STEP 2: Use Gemini AI to parse the raw text into structured timetable
      final aiSlots = await _parseWithGemini(rawText);
      if (aiSlots.isNotEmpty) {
        debugPrint('LUMINA: Gemini parsed ${aiSlots.length} class slots successfully.');
        return TimetableImportResult.success(
          filePath: filePath,
          sourceType: type,
          rawText: rawText,
          slots: aiSlots,
          issues: [],
        );
      }

      // STEP 3: Fall back to regex parser
      debugPrint('LUMINA: Gemini parsing failed, trying regex parser...');
      final parsed = parser.parseRawText(rawText);
      
      // Check if regex gave good results (not all "Untitled Class")
      final goodSlots = parsed.slots.where((s) => s.subject != 'Untitled Class').toList();
      if (goodSlots.isNotEmpty) {
        return TimetableImportResult.success(
          filePath: filePath,
          sourceType: type,
          rawText: rawText,
          slots: parsed.slots,
          issues: parsed.issues,
        );
      }

      // STEP 4: If we got time slots but no subjects, still return them 
      // but with issues so user can edit
      if (parsed.slots.isNotEmpty) {
        return TimetableImportResult.success(
          filePath: filePath,
          sourceType: type,
          rawText: rawText,
          slots: parsed.slots,
          issues: [
            const ParseIssue(
              lineNumber: 0,
              message: 'Subject names could not be detected. Tap each class to edit.',
              rawLine: '',
            ),
            ...parsed.issues,
          ],
        );
      }

      return TimetableImportResult.failure(
        filePath: filePath,
        sourceType: type,
        message: 'Could not detect any timetable entries. Make sure the file contains a class schedule with days and times.',
        rawText: rawText,
        issues: parsed.issues,
      );
    } catch (e) {
      debugPrint('LUMINA: Import error: $e');
      return TimetableImportResult.failure(
        filePath: filePath,
        sourceType: type,
        message: 'Error processing file: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}',
      );
    }
  }

  /// Use Gemini AI to intelligently parse raw timetable text
  Future<List<ParsedClassSlot>> _parseWithGemini(String rawText) async {
    try {
      final gemini = GeminiService.instance;
      if (!gemini.isInitialized) return [];

      // Limit text length to avoid token limits
      final truncated = rawText.length > 4000 ? rawText.substring(0, 4000) : rawText;

      final prompt = '''Parse this college timetable text into a JSON array. Each entry should have:
- "day": weekday name (Monday/Tuesday/Wednesday/Thursday/Friday)  
- "start": start time in 24h format (HH:MM)
- "end": end time in 24h format (HH:MM)
- "subject": subject/course name
- "room": room/lab number (use "TBA" if not found)

Return ONLY a valid JSON array, no other text. Example:
[{"day":"Monday","start":"09:00","end":"10:00","subject":"Data Structures","room":"LH-301"}]

Here is the timetable text:
$truncated''';

      final response = await gemini.generateText(prompt);
      
      // Extract JSON from response
      final jsonStr = _extractJson(response);
      if (jsonStr == null) return [];

      final List<dynamic> parsed = jsonDecode(jsonStr);
      final slots = <ParsedClassSlot>[];

      for (final entry in parsed) {
        if (entry is! Map<String, dynamic>) continue;
        
        final day = entry['day'] as String? ?? '';
        final start = entry['start'] as String? ?? '';
        final end = entry['end'] as String? ?? '';
        final subject = entry['subject'] as String? ?? 'Untitled Class';
        final room = entry['room'] as String? ?? 'TBA';

        if (day.isEmpty || start.isEmpty || end.isEmpty) continue;

        // Normalize day name
        final normalizedDay = _normalizeDayName(day);
        if (normalizedDay == null) continue;

        final duration = parser._minutesBetween(start, end) ?? 60;

        slots.add(ParsedClassSlot(
          day: normalizedDay,
          startTime24: start,
          endTime24: end,
          subject: subject,
          room: room,
          durationMinutes: duration <= 0 ? 60 : duration,
          confidence: 0.85,
          sourceLine: 'AI parsed',
        ));
      }

      return slots;
    } catch (e) {
      debugPrint('Gemini parse error: $e');
      return [];
    }
  }

  String? _extractJson(String text) {
    // Try to find JSON array in the response
    final bracketStart = text.indexOf('[');
    final bracketEnd = text.lastIndexOf(']');
    if (bracketStart >= 0 && bracketEnd > bracketStart) {
      return text.substring(bracketStart, bracketEnd + 1);
    }
    return null;
  }

  String? _normalizeDayName(String day) {
    final lower = day.toLowerCase().trim();
    const map = {
      'monday': 'Monday', 'mon': 'Monday',
      'tuesday': 'Tuesday', 'tue': 'Tuesday', 'tues': 'Tuesday',
      'wednesday': 'Wednesday', 'wed': 'Wednesday',
      'thursday': 'Thursday', 'thu': 'Thursday', 'thur': 'Thursday', 'thurs': 'Thursday',
      'friday': 'Friday', 'fri': 'Friday',
      'saturday': 'Saturday', 'sat': 'Saturday',
    };
    return map[lower];
  }

  Future<String> _extractTextFromPdf(File file) async {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: await file.readAsBytes());
      final String text = PdfTextExtractor(document).extractText();
      return text;
    } catch (e) {
      debugPrint('PDF Extraction Error: $e');
      return '';
    } finally {
      document?.dispose();
    }
  }

  Future<String> _extractTextFromImage(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      await textRecognizer.close();
      return text;
    } catch (e) {
      debugPrint('Image OCR Error: $e');
      return '';
    }
  }

  Future<TimetableImportResult> _importViaGradio(String filePath, TimetableImportType type) async {
    try {
      final file = File(filePath);
      final remotePath = await _gradioService.uploadFile(file);
      if (remotePath == null) {
        return TimetableImportResult.failure(
          filePath: filePath,
          sourceType: type,
          message: 'Lumina could not process this file at the moment.',
        );
      }

      final result = await _gradioService.callEndpoint('process_timetable', [
        {'path': remotePath}
      ]);

      if (result == null || result is! List || result.isEmpty) {
        return TimetableImportResult.failure(
          filePath: filePath,
          sourceType: type,
          message: 'Lumina could not analyze the timetable structure.',
        );
      }

      final data = result[0] as Map<String, dynamic>;
      final rawText = data['raw_text'] as String? ?? '';
      _lastRawExtractedText = rawText;

      final parsed = parser.parseRawText(rawText);
      if (parsed.slots.isEmpty) {
        return TimetableImportResult.failure(
          filePath: filePath,
          sourceType: type,
          message: 'No timetable entries detected.',
          rawText: rawText,
          issues: parsed.issues,
        );
      }

      return TimetableImportResult.success(
        filePath: filePath,
        sourceType: type,
        rawText: rawText,
        slots: parsed.slots,
        issues: parsed.issues,
        fullJson: data,
      );
    } catch (e) {
      return TimetableImportResult.failure(
        filePath: filePath,
        sourceType: type,
        message: 'Lumina experienced a connection issue.',
      );
    }
  }

  Future<void> saveOcrExtraction(Map<String, dynamic> json) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('timetable_ocr_extractions').insert({
        'user_id': user.id,
        'raw_json': json,
      });
    } catch (e) {
      debugPrint('Error saving OCR extraction: $e');
    }
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
    notifyListeners();
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
    notifyListeners();
  }

  void loadDemoData() {
    _schedule = AppConstants.demoTimetable.map((dayData) {
      final String day = dayData['day'];
      final List<dynamic> classesData = dayData['classes'];
      final List<TimetableEntry> classes = classesData.map((c) {
        return TimetableEntry(
          subject: c['subject'],
          time: c['time'],
          room: c['room'],
          durationMinutes: c['duration'],
        );
      }).toList();
      return DaySchedule(day: day, classes: classes);
    }).toList();
    _isLoaded = true;
    notifyListeners();
  }

  int _compareEntryByTime(TimetableEntry a, TimetableEntry b) {
    final ma = _minutesFromDisplayTime(a.time) ?? 0;
    final mb = _minutesFromDisplayTime(b.time) ?? 0;
    return ma.compareTo(mb);
  }

  int? _minutesFromDisplayTime(String time) {
    final parser = this.parser;
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
