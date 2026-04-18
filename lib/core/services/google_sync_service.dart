import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
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

class GoogleSyncService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarScope,
      gmail.GmailApi.gmailReadonlyScope,
    ],
  );

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int _stressLevel = 0; // 0: Green, 1: Moderate, 2: Red
  int get stressLevel => _stressLevel;
  
  final List<String> _upcomingDeadlines = [];
  List<String> get upcomingDeadlines => List.unmodifiable(_upcomingDeadlines);

  Future<void> syncAcademicLife() async {
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

      final gmailApi = gmail.GmailApi(authClient);
      final calendarApi = calendar.CalendarApi(authClient);

      // 1. SCAN GMAIL FOR DEADLINES
      final response = await gmailApi.users.messages.list(
        'me',
        q: 'subject:deadline OR subject:assignment OR subject:exam OR subject:submission newer_than:7d',
      );

      final messages = response.messages ?? [];
      int deadlinesFound = 0;
      _upcomingDeadlines.clear();

      // 2. PROCESS EMAILS
      for (var msg in messages) {
        final fullMessage = await gmailApi.users.messages.get('me', msg.id!);
        final snippet = fullMessage.snippet ?? '';
        
        // Push the deadline to the UI list
        _upcomingDeadlines.add(snippet);
        deadlinesFound++;
        
        // 3. PUSH TO GOOGLE CALENDAR
        final event = calendar.Event(
          summary: '⚠️ DEADLINE: ${snippet.substring(0, snippet.length > 30 ? 30 : snippet.length)}...',
          start: calendar.EventDateTime(
            dateTime: DateTime.now().add(Duration(days: 2)), // Simulated extraction date
          ),
          end: calendar.EventDateTime(
            dateTime: DateTime.now().add(Duration(days: 2, hours: 1)),
          ),
          colorId: '11', // Red color for high stress in Google Calendar
        );

        try {
          await calendarApi.events.insert(event, 'primary');
        } catch (e) {
          debugPrint('Error inserting calendar event: $e');
        }
      }

      // 4. CALCULATE STRESS LEVEL HEATMAP
      if (deadlinesFound >= 3) {
        _stressLevel = 2; // High Stress (Red)
      } else if (deadlinesFound > 0) {
        _stressLevel = 1; // Moderate Stress (Yellow)
      } else {
        _stressLevel = 0; // Low Stress (Green)
      }

    } catch (e) {
      debugPrint('Error syncing academic life: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void signOut() async {
    await _googleSignIn.signOut();
    _stressLevel = 0;
    _upcomingDeadlines.clear();
    notifyListeners();
  }
}
