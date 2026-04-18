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
  final List<AcademicDeadline> _deadlines = [];
  bool _isSyncing = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar_api.CalendarApi.calendarScope,
      gmail_api.GmailApi.gmailReadonlyScope,
    ],
  );

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
    _deadlines.clear();
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
    ]);
    notifyListeners();
  }

  Future<void> syncGmail() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _isSyncing = false;
        notifyListeners();
        return; // User canceled
      }

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);

      final gmailClient = gmail_api.GmailApi(authClient);
      final calClient = calendar_api.CalendarApi(authClient);

      // 1. SCAN GMAIL FOR DEADLINES
      final String query = "${academicKeywords.map((kw) => 'subject:$kw').join(' OR ')} newer_than:7d";
      final response = await gmailClient.users.messages.list('me', q: query);

      final messages = response.messages ?? [];
      final now = DateTime.now();

      for (var msg in messages) {
        if (msg.id == null) {
          continue;
        }
        final fullMessage = await gmailClient.users.messages.get('me', msg.id!);
        final snippet = fullMessage.snippet ?? 'Academic Deadline';
        
        // Simple regex to extract dates could go here. For now, simulate +2 days.
        final simulatedDate = now.add(const Duration(days: 2));

        final deadline = AcademicDeadline(
          title: snippet.length > 40 ? '${snippet.substring(0, 40)}...' : snippet,
          date: simulatedDate,
          source: 'Gmail',
          keyword: academicKeywords.firstWhere(
            (kw) => snippet.toLowerCase().contains(kw.toLowerCase()),
            orElse: () => 'Deadline',
          ),
        );

        if (!_deadlines.any((existing) => existing.title == deadline.title)) {
          _deadlines.add(deadline);

          // 2. PUSH TO GOOGLE CALENDAR
          final event = calendar_api.Event(
            summary: '⚠️ LUMINA DEADLINE: ${deadline.title}',
            start: calendar_api.EventDateTime(dateTime: simulatedDate),
            end: calendar_api.EventDateTime(dateTime: simulatedDate.add(const Duration(hours: 1))),
            colorId: '11', // Red color
          );

          try {
            await calClient.events.insert(event, 'primary');
          } catch (e) {
            debugPrint('Failed to sync to GCal: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing Gmail/Calendar: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  StressState get stressState {
    if (_deadlines.isEmpty) {
      return StressState.green;
    }

    // Logic: if 3+ deadlines collide on a single day -> Red
    final Map<String, int> collisionMap = {};
    for (var d in _deadlines) {
      final dateKey = "${d.date.year}-${d.date.month}-${d.date.day}";
      collisionMap[dateKey] = (collisionMap[dateKey] ?? 0) + 1;
    }

    bool hasTripleCollision = collisionMap.values.any((count) => count >= 3);
    if (hasTripleCollision) {
      return StressState.red;
    }

    // Logic: if week is clear -> Green
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    bool hasDeadlinesThisWeek = _deadlines.any((d) => d.date.isBefore(nextWeek));
    
    if (!hasDeadlinesThisWeek) {
      return StressState.green;
    }

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
      if (count >= 4) {
        intensity = 1.0;
      } else if (count == 3) {
        intensity = 0.7;
      } else if (count >= 1) {
        intensity = 0.4;
      }
      heatmap[date] = intensity;
    });

    return heatmap;
  }

  double get deadlineProximityScore {
    if (_deadlines.isEmpty) {
      return 0;
    }
    
    final now = DateTime.now();
    double totalProximity = 0;
    
    for (var d in _deadlines) {
      final diff = d.date.difference(now).inDays;
      if (diff < 0) {
        continue; // Past deadline
      }
      
      // Closer the deadline, higher the score
      // 0 days = 100 points, 7 days = 0 points
      if (diff <= 7) {
        totalProximity += (7 - diff) * 14.28; // Normalize to ~100
      }
    }
    
    return (totalProximity / (_deadlines.length.clamp(1, 10))).clamp(0, 100);
  }
}
