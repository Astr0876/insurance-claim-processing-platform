import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:googleapis/gmail/v1.dart' as gmail_api;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final String source; // 'Google Calendar', 'Gmail', 'Manual'
  final String? location;
  final bool isAllDay;

  CalendarEvent({
    required this.title,
    required this.start,
    this.end,
    required this.source,
    this.location,
    this.isAllDay = false,
  });
}

class AcademicDeadline {
  final String title;
  final DateTime date;
  final String source; // e.g., 'Gmail', 'Manual', 'Google Calendar'
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
  final List<AcademicDeadline> _deadlines = [];
  final List<CalendarEvent> _calendarEvents = [];
  bool _isSyncing = false;
  String? _syncError;
  int _emailsScanned = 0;
  int _eventsFound = 0;


  static const _clientId = '281609918138-v038qckesd26sq7puc39m7bpe4ueob0e.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar_api.CalendarApi.calendarScope,
      gmail_api.GmailApi.gmailReadonlyScope,
    ],
    serverClientId: _clientId,
  );

  List<AcademicDeadline> get deadlines => _deadlines;
  List<CalendarEvent> get calendarEvents => _calendarEvents;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get emailsScanned => _emailsScanned;
  int get eventsFound => _eventsFound;

  static const List<String> academicKeywords = [
    'Submission', 'Deadline', 'Exam', 'Lab', 'Viva',
    'Assignment', 'Project', 'Quiz', 'Lecture', 'Class',
    'Tutorial', 'Workshop', 'Seminar', 'Test', 'Presentation',
  ];

  void loadDemoData() {
    final now = DateTime.now();
    _deadlines.clear();
    _calendarEvents.clear();
    _deadlines.addAll([
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
      AcademicDeadline(
        title: 'CN Assignment Due',
        date: now.add(const Duration(days: 5)),
        source: 'Gmail',
        keyword: 'Assignment',
      ),
    ]);
    _calendarEvents.addAll([
      CalendarEvent(title: 'Data Structures Lecture', start: now.add(const Duration(hours: 2)), source: 'Google Calendar', location: 'Room 301'),
      CalendarEvent(title: 'OS Lab', start: now.add(const Duration(days: 1, hours: 3)), source: 'Google Calendar', location: 'Lab 2'),
      CalendarEvent(title: 'DBMS Tutorial', start: now.add(const Duration(days: 2, hours: 1)), source: 'Google Calendar'),
      CalendarEvent(title: 'CN Workshop', start: now.add(const Duration(days: 3, hours: 4)), source: 'Google Calendar', location: 'Seminar Hall'),
    ]);
    notifyListeners();
  }

  /// Full sync: Fetch Google Calendar events + Scan Gmail for deadlines
  Future<void> syncGmail() async {
    _isSyncing = true;
    _syncError = null;
    _emailsScanned = 0;
    _eventsFound = 0;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _syncError = 'Google Sign-In was cancelled. Demo data loaded.';
        if (_deadlines.isEmpty && _calendarEvents.isEmpty) {
          loadDemoData();
        }
        _isSyncing = false;
        notifyListeners();
        return;
      }

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);

      // Run both in parallel
      await Future.wait([
        _fetchCalendarEvents(authClient),
        _scanGmailForDeadlines(authClient),
      ]);

    } catch (e) {
      debugPrint('Error syncing: $e');
      _syncError = e.toString();
      // Load demo data as fallback so the UI isn't empty
      if (_deadlines.isEmpty && _calendarEvents.isEmpty) {
        loadDemoData();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Fetch upcoming events from Google Calendar
  Future<void> _fetchCalendarEvents(http.BaseClient authClient) async {
    try {
      final calClient = calendar_api.CalendarApi(authClient);
      
      final now = DateTime.now();
      final twoWeeksLater = now.add(const Duration(days: 14));

      final events = await calClient.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: twoWeeksLater.toUtc(),
        maxResults: 50,
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items != null) {
        for (final event in events.items!) {
          if (event.summary == null) continue;
          
          final isAllDay = event.start?.date != null;
          DateTime? startTime;
          
          if (isAllDay) {
            startTime = event.start!.date;
          } else {
            startTime = event.start?.dateTime?.toLocal();
          }
          
          if (startTime == null) continue;

          final calEvent = CalendarEvent(
            title: event.summary!,
            start: startTime,
            end: isAllDay ? event.end?.date : event.end?.dateTime?.toLocal(),
            source: 'Google Calendar',
            location: event.location,
            isAllDay: isAllDay,
          );

          // Don't duplicate
          if (!_calendarEvents.any((e) => e.title == calEvent.title && e.start == calEvent.start)) {
            _calendarEvents.add(calEvent);
            _eventsFound++;
          }

          // Also check if it matches academic keywords → add as deadline
          final lowerTitle = event.summary!.toLowerCase();
          for (final kw in academicKeywords) {
            if (lowerTitle.contains(kw.toLowerCase())) {
              final deadline = AcademicDeadline(
                title: event.summary!,
                date: startTime,
                source: 'Google Calendar',
                keyword: kw,
              );
              if (!_deadlines.any((d) => d.title == deadline.title)) {
                _deadlines.add(deadline);
              }
              break;
            }
          }
        }
      }
      
      // Sort events by start time
      _calendarEvents.sort((a, b) => a.start.compareTo(b.start));
      debugPrint('Calendar: Fetched ${_eventsFound} events');
    } catch (e) {
      debugPrint('Calendar fetch error: $e');
    }
  }

  /// Scan Gmail for academic keywords and extract deadlines
  Future<void> _scanGmailForDeadlines(http.BaseClient authClient) async {
    try {
      final gmailClient = gmail_api.GmailApi(authClient);

      // Search for academic emails from last 14 days
      final String query = "${academicKeywords.take(8).map((kw) => 'subject:$kw').join(' OR ')} newer_than:14d";
      final response = await gmailClient.users.messages.list('me', q: query, maxResults: 20);

      final messages = response.messages ?? [];
      _emailsScanned = messages.length;

      for (var msg in messages) {
        if (msg.id == null) continue;
        
        try {
          final fullMessage = await gmailClient.users.messages.get('me', msg.id!, format: 'metadata');
          
          // Get subject from headers
          String subject = 'Academic Deadline';
          DateTime? emailDate;
          
          if (fullMessage.payload?.headers != null) {
            for (final header in fullMessage.payload!.headers!) {
              if (header.name?.toLowerCase() == 'subject') {
                subject = header.value ?? subject;
              }
              if (header.name?.toLowerCase() == 'date') {
                emailDate = _parseEmailDate(header.value);
              }
            }
          }

          // Use email date + 7 days as likely deadline, or 3 days from now
          final deadlineDate = emailDate != null 
              ? emailDate.add(const Duration(days: 7))
              : DateTime.now().add(const Duration(days: 3));

          // Only add future deadlines
          if (deadlineDate.isAfter(DateTime.now())) {
            final matchedKeyword = academicKeywords.firstWhere(
              (kw) => subject.toLowerCase().contains(kw.toLowerCase()),
              orElse: () => 'Deadline',
            );

            final deadline = AcademicDeadline(
              title: subject.length > 60 ? '${subject.substring(0, 60)}...' : subject,
              date: deadlineDate,
              source: 'Gmail',
              keyword: matchedKeyword,
            );

            if (!_deadlines.any((existing) => existing.title == deadline.title)) {
              _deadlines.add(deadline);
            }
          }
        } catch (e) {
          debugPrint('Error processing email ${msg.id}: $e');
        }
      }

      // Sort deadlines by date
      _deadlines.sort((a, b) => a.date.compareTo(b.date));
      debugPrint('Gmail: Scanned $_emailsScanned emails, found ${_deadlines.length} deadlines');
    } catch (e) {
      debugPrint('Gmail scan error: $e');
    }
  }

  /// Try to parse email Date header
  DateTime? _parseEmailDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // Try ISO 8601 first
      final iso = DateTime.tryParse(dateStr);
      if (iso != null) return iso;
      
      // Try RFC 2822: "Fri, 18 Apr 2025 10:30:00 +0530"
      // Strip day-name prefix if present
      var cleaned = dateStr.replaceAll(RegExp(r'^[A-Za-z]+,?\s*'), '');
      // Try parsing the remaining
      return DateTime.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Get events for a specific day
  List<CalendarEvent> eventsForDay(DateTime day) {
    return _calendarEvents.where((e) {
      return e.start.year == day.year && e.start.month == day.month && e.start.day == day.day;
    }).toList();
  }

  /// Get deadlines for a specific day
  List<AcademicDeadline> deadlinesForDay(DateTime day) {
    return _deadlines.where((d) {
      return d.date.year == day.year && d.date.month == day.month && d.date.day == day.day;
    }).toList();
  }

  StressState get stressState {
    if (_deadlines.isEmpty) return StressState.green;

    final Map<String, int> collisionMap = {};
    for (var d in _deadlines) {
      final dateKey = "${d.date.year}-${d.date.month}-${d.date.day}";
      collisionMap[dateKey] = (collisionMap[dateKey] ?? 0) + 1;
    }

    if (collisionMap.values.any((count) => count >= 3)) return StressState.red;

    final nextWeek = DateTime.now().add(const Duration(days: 7));
    if (_deadlines.any((d) => d.date.isBefore(nextWeek))) return StressState.yellow;

    return StressState.green;
  }

  Map<DateTime, double> get deadlineHeatmap {
    final Map<DateTime, double> heatmap = {};
    final Map<String, int> counts = {};
    
    // Count deadlines per day
    for (var d in _deadlines) {
      final dateOnly = DateTime(d.date.year, d.date.month, d.date.day);
      counts[dateOnly.toString()] = (counts[dateOnly.toString()] ?? 0) + 1;
    }
    
    // Count calendar events per day
    for (var e in _calendarEvents) {
      final dateOnly = DateTime(e.start.year, e.start.month, e.start.day);
      counts[dateOnly.toString()] = (counts[dateOnly.toString()] ?? 0) + 1;
    }

    counts.forEach((dateStr, count) {
      final date = DateTime.parse(dateStr);
      double intensity;
      if (count >= 4) {
        intensity = 1.0;
      } else if (count == 3) {
        intensity = 0.7;
      } else if (count >= 1) {
        intensity = 0.4;
      } else {
        intensity = 0.0;
      }
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
      if (diff < 0) continue;
      if (diff <= 7) {
        totalProximity += (7 - diff) * 14.28;
      }
    }
    
    return (totalProximity / (_deadlines.length.clamp(1, 10))).clamp(0, 100);
  }
}
