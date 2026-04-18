// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/services/hub_service.dart
//  REST + Supabase Realtime service for Collaborative Study Hub
//  Falls back to local simulation if Supabase is unreachable.
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hub_models.dart';

class HubService extends ChangeNotifier {
  // ── Supabase ────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _hubChannel;
  bool get isConnected => _hubChannel != null;

  // ── Identity (Supabase) ──────────────────────────────────────────
  String get userId => _supabase.auth.currentUser?.id ?? 'user_anonymous';
  String get userName => _supabase.auth.currentUser?.userMetadata?['student_name'] ?? 'Student';

  void setIdentity(String id, String name) {
    // Identity is now primarily derived from Supabase Auth
  }

  // ── State ─────────────────────────────────────────────────────────
  List<StudyRoom>   myRooms      = [];
  StudyRoom?        currentRoom;
  List<HubMessage>  messages     = [];
  List<PresenceInfo> presence    = [];
  List<HubPoll>     polls        = [];
  List<PinnedItem>  pinnedItems  = [];
  List<ActivityItem> activities  = [];
  List<Map<String, dynamic>> sketches = [];
  StudySession?     studySession;
  String            docContent   = '';
  int               docVersion   = 0;
  String            codeContent  = '';
  int               codeVersion  = 0;

  // --- Study Squads Flow Trend ---
  final List<double> _flowTrend = [];
  List<double> get flowTrend => List.unmodifiable(_flowTrend);

  void updateFlowTrend(List<double> rawScores) {
    if (rawScores.isEmpty) return;
    final avg = rawScores.reduce((a, b) => a + b) / rawScores.length;
    _flowTrend.add(avg);
    if (_flowTrend.length > 50) _flowTrend.removeAt(0);
    notifyListeners();
  }

  Map<String, bool> typingUsers = {}; // userId -> isTyping
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? errorMessage;

  // ── Timers ────────────────────────────────────────────────────────
  Timer? _presenceTimer;
  Timer? _sessionTimer;
  int _sessionTick = 0;
  int get sessionElapsedSeconds => _sessionTick;

  // ─────────────────────────────────────────────────────────────────
  //  INITIALISE / CONNECT
  // ─────────────────────────────────────────────────────────────────

  void connect() {
    try {
      // Initialize Supabase Realtime Channel
      _hubChannel = _supabase.channel('public:hub_messages');

      // 1. Subscribe to INSERT events for the hub_messages table
      _hubChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'hub_messages',
        callback: (payload) {
          final record = payload.newRecord;
          if (currentRoom != null && record['room_id'] == currentRoom!.id) {
            final sId = record['sender_id']?.toString() ?? '';
            
            // Try to resolve sender name from current room members
            String sName = 'Student';
            if (currentRoom != null) {
              final member = currentRoom!.members.firstWhere(
                (m) => m.userId == sId,
                orElse: () => RoomMember(userId: sId, name: 'Student', role: 'viewer', joinedAt: ''),
              );
              sName = member.name;
            }

            final msg = HubMessage(
              id: record['id']?.toString() ?? '',
              roomId: record['room_id']?.toString() ?? '',
              senderId: sId,
              senderName: sName,
              content: record['content']?.toString() ?? '',
              type: record['type']?.toString() ?? 'text',
              createdAt: record['created_at']?.toString() ?? '',
              readBy: [],
            );
            
            // Avoid duplicate additions if echo already added it
            if (!messages.any((m) => m.id == msg.id)) {
              messages.add(msg);
              notifyListeners();
            }
          }
        },
      ).subscribe();

      // 2. Listen for other realtime updates via Broadcast
      _hubChannel!.onBroadcast(event: 'typing', callback: (data) {
        final uid = data['userId'] as String;
        final isTyping = data['isTyping'] as bool;
        if (uid != userId) {
          if (isTyping) {
            typingUsers[uid] = true;
          } else {
            typingUsers.remove(uid);
          }
          notifyListeners();
        }
      });

      _hubChannel!.onBroadcast(event: 'doc_update', callback: (data) {
        final incomingVersion = data['version'] ?? 0;
        if (incomingVersion >= docVersion) {
          docContent = data['content'] ?? '';
          docVersion = incomingVersion;
          notifyListeners();
        }
      });

      _hubChannel!.onBroadcast(event: 'code_update', callback: (data) {
        final incomingVersion = data['version'] ?? 0;
        if (incomingVersion >= codeVersion) {
          codeContent = data['content'] ?? '';
          codeVersion = incomingVersion;
          notifyListeners();
        }
      });

      _hubChannel!.onBroadcast(event: 'sketch', callback: (data) {
        if (data['data']?['action'] == 'clear') {
          sketches.clear();
        } else {
          sketches.add(Map<String, dynamic>.from(data));
        }
        notifyListeners();
      });

      _hubChannel!.onBroadcast(event: 'poll_update', callback: (data) {
        final poll = HubPoll.fromJson(Map<String, dynamic>.from(data['poll']));
        final idx  = polls.indexWhere((p) => p.id == poll.id);
        if (idx >= 0) {
          polls[idx] = poll;
        } else {
          polls.add(poll);
        }
        notifyListeners();
      });

      _hubChannel!.onBroadcast(event: 'session_update', callback: (data) {
        if (data['active'] == false) {
          studySession = null;
          _sessionTimer?.cancel();
          _sessionTick = 0;
        } else {
          studySession = StudySession.fromJson(Map<String, dynamic>.from(data));
          _startSessionTick();
        }
        notifyListeners();
      });

      notifyListeners();

    } catch (e) {
      debugPrint('HubService: Supabase connect error $e');
    }
  }

  void _startSessionTick() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionTick++;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────────
  //  ROOM ACTIONS
  // ─────────────────────────────────────────────────────────────────

  Future<void> fetchMyRooms() async {
    _isLoading = true;
    notifyListeners();
    errorMessage = null;

    try {
      final currentUserId = userId;
      if (currentUserId == 'user_anonymous') {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<dynamic> allData = await _supabase
          .from('study_rooms')
          .select('*, room_members(*)');

      myRooms = allData.where((room) {
        final members = room['room_members'] as List;
        return members.any((m) => m['user_id'] == currentUserId);
      }).map((roomData) {
        final Map<String, dynamic> mappedData = {
          'id': roomData['id'].toString(),
          'name': roomData['name'],
          'code': roomData['code'],
          'ownerId': roomData['owner_id'],
          'createdAt': roomData['created_at'],
          'members': (roomData['room_members'] as List).map((m) => {
            'userId': m['user_id'],
            'name': m['user_name'] ?? 'User',
            'role': m['role'],
            'joinedAt': m['joined_at'],
          }).toList(),
        };
        return StudyRoom.fromJson(mappedData);
      }).toList();

    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      loadDemoRooms();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StudyRoom?> createRoom(String name) async {
    _isLoading = true;
    notifyListeners();
    errorMessage = null;
    try {
      final code = _randomCode();
      final currentUserId = userId;
      final currentUserName = userName;

      final roomResult = await _supabase.from('study_rooms').insert({
        'name': name,
        'code': code,
        'owner_id': currentUserId,
      }).select().single();

      final roomId = roomResult['id'];

      await _supabase.from('room_members').insert({
        'room_id': roomId,
        'user_id': currentUserId,
        'user_name': currentUserName,
        'role': 'admin',
      });

      await fetchMyRooms();
      _isLoading = false;
      notifyListeners();
      return myRooms.firstWhere((r) => r.id == roomId);
    } catch (e) {
      debugPrint('Error creating room: $e');
      errorMessage = 'Failed to create room';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<StudyRoom?> joinRoom(String code) async {
    _isLoading = true;
    notifyListeners();
    errorMessage = null;
    try {
      final roomMatch = await _supabase
          .from('study_rooms')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (roomMatch == null) {
        errorMessage = 'Room not found';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final roomId = roomMatch['id'];
      final currentUserId = userId;
      final currentUserName = userName;

      final existingMember = await _supabase
          .from('room_members')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingMember == null) {
        await _supabase.from('room_members').insert({
          'room_id': roomId,
          'user_id': currentUserId,
          'user_name': currentUserName,
          'role': 'viewer',
        });
      }

      await fetchMyRooms();
      _isLoading = false;
      notifyListeners();
      return myRooms.firstWhere((r) => r.id == roomId);
    } catch (e) {
      debugPrint('Error joining room: $e');
      errorMessage = 'Failed to join room';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  void enterRoom(StudyRoom room) {
    currentRoom = room;
    messages    = [];
    presence    = [];
    polls       = [];
    pinnedItems = [];
    activities  = [];
    docContent  = '';
    typingUsers = {};
    studySession = null;
    notifyListeners();

    if (!isConnected) {
      _loadDemoState(room.id);
    }
  }

  void leaveRoom() {
    currentRoom = null;
    _sessionTimer?.cancel();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  //  MESSAGING
  // ─────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content, {String type = 'text'}) async {
    if (currentRoom == null) return;

    if (isConnected) {
      try {
        await _supabase.from('hub_messages').insert({
          'room_id': currentRoom!.id,
          'sender_id': userId,
          'content': content,
          'type': type,
        });
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    } else {
      // Demo local echo
      messages.add(HubMessage(
        id: _uid(),
        roomId: currentRoom!.id,
        senderId: userId,
        senderName: userName,
        content: content,
        type: type,
        createdAt: DateTime.now().toIso8601String(),
        readBy: [],
      ));
      _addDemoReply();
      notifyListeners();
    }
  }

  void sendTyping(bool isTyping) {
    if (currentRoom == null || !isConnected) return;
    try {
      _hubChannel?.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'roomId': currentRoom!.id,
          'userId': userId,
          'userName': userName,
          'isTyping': isTyping,
        },
      );
    } catch (e) {
      debugPrint('Broadcast error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  DOCUMENT
  // ─────────────────────────────────────────────────────────────────

  void updateDoc(String content) {
    docContent = content;
    docVersion++;
    if (currentRoom == null) return;
    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'doc_update',
        payload: {
          'roomId': currentRoom!.id,
          'userId': userId,
          'content': content,
          'version': docVersion,
        },
      );
    }
    notifyListeners();
  }

  void updateCode(String content) {
    codeContent = content;
    codeVersion++;
    if (currentRoom == null) return;
    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'code_update',
        payload: {
          'roomId': currentRoom!.id,
          'userId': userId,
          'content': content,
          'version': codeVersion,
        },
      );
    }
    notifyListeners();
  }

  void sendSketch(Map<String, dynamic> data) {
    if (currentRoom == null) return;
    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'sketch',
        payload: {
          'roomId': currentRoom!.id,
          'userId': userId,
          'data': data,
        },
      );
    }
    if (data['action'] == 'clear') {
      sketches.clear();
    } else {
      sketches.add({'userId': userId, 'data': data, 'timestamp': DateTime.now().toIso8601String()});
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  //  POLLS
  // ─────────────────────────────────────────────────────────────────

  void createPoll(String question) {
    if (currentRoom == null) return;
    final poll = HubPoll(
      id: _uid(),
      roomId: currentRoom!.id,
      creatorId: userId,
      question: question,
      yes: [],
      no: [],
      createdAt: DateTime.now().toIso8601String(),
    );
    polls.add(poll);
    notifyListeners();

    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'poll_update',
        payload: {'poll': poll.toJson()},
      );
    }
  }

  void votePoll(String pollId, String vote) {
    final poll = polls.firstWhere((p) => p.id == pollId);
    poll.yes.remove(userId);
    poll.no.remove(userId);
    if (vote == 'yes') {
      poll.yes.add(userId);
    } else {
      poll.no.add(userId);
    }
    notifyListeners();

    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'poll_update',
        payload: {'poll': poll.toJson()},
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PINS
  // ─────────────────────────────────────────────────────────────────

  void pinItem({required String itemType, required String content, required String label}) {
    final pin = PinnedItem(
      id: _uid(),
      userId: userId,
      itemType: itemType,
      content: content,
      label: label,
      pinnedAt: DateTime.now().toIso8601String(),
    );
    pinnedItems.insert(0, pin);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  //  STUDY SESSION
  // ─────────────────────────────────────────────────────────────────

  void startSession() {
    if (currentRoom == null) return;
    studySession = StudySession(
      roomId: currentRoom!.id,
      startedBy: userId,
      startedAt: DateTime.now().toIso8601String(),
      activeUsers: [userId],
    );
    _sessionTick = 0;
    _startSessionTick();
    notifyListeners();

    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'session_update',
        payload: studySession!.toJson(),
      );
    }
  }

  void stopSession() {
    studySession = null;
    _sessionTimer?.cancel();
    _sessionTick = 0;
    notifyListeners();

    if (isConnected) {
      _hubChannel?.sendBroadcastMessage(
        event: 'session_update',
        payload: {'active': false},
      );
    }
  }

  String get sessionDisplay {
    final m = _sessionTick ~/ 60;
    final s = _sessionTick % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────
  //  INSIGHTS
  // ─────────────────────────────────────────────────────────────────

  String get mostActiveUser {
    final counts = <String, int>{};
    for (final m in messages) {
      if (!m.isSystem) counts[m.senderName] = (counts[m.senderName] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int get totalMessages => messages.where((m) => !m.isSystem).length;

  // ─────────────────────────────────────────────────────────────────
  //  DEMO FALLBACK
  // ─────────────────────────────────────────────────────────────────

  void loadDemoRooms() {
    myRooms = [
      _makeDemoRoom('Data Structures Study'),
      _makeDemoRoom('OS Exam Prep'),
      _makeDemoRoom('CN Hackathon Squad'),
    ];
    notifyListeners();
  }

  StudyRoom _makeDemoRoom(String name) {
    return StudyRoom(
      id: _uid(),
      name: name,
      ownerId: userId,
      members: [
        RoomMember(userId: userId, name: userName, role: 'admin', joinedAt: DateTime.now().toIso8601String()),
        RoomMember(userId: 'u2', name: 'Priya', role: 'editor', joinedAt: DateTime.now().toIso8601String()),
        RoomMember(userId: 'u3', name: 'Rahul', role: 'viewer', joinedAt: DateTime.now().toIso8601String()),
      ],
      code: _randomCode(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  void _loadDemoState(String roomId) {
    presence = [
      PresenceInfo(userId: userId,  userName: userName, status: 'active',  lastSeen: DateTime.now().toIso8601String()),
      PresenceInfo(userId: 'u2',    userName: 'Priya',  status: 'active',  lastSeen: DateTime.now().toIso8601String()),
      PresenceInfo(userId: 'u3',    userName: 'Rahul',  status: 'idle',    lastSeen: DateTime.now().toIso8601String()),
    ];
    messages = [
      HubMessage(id: _uid(), roomId: roomId, senderId: 'system', senderName: 'System', content: 'Welcome to the room! 🎉', type: 'system', createdAt: _ago(5), readBy: []),
      HubMessage(id: _uid(), roomId: roomId, senderId: 'u2', senderName: 'Priya', content: 'Hey! Should we start with Unit 3?', type: 'text', createdAt: _ago(3), readBy: [userId]),
      HubMessage(id: _uid(), roomId: roomId, senderId: 'u3', senderName: 'Rahul', content: 'Unit 3 has deadlocks — tricky stuff 😅', type: 'text', createdAt: _ago(2), readBy: []),
    ];
    polls = [
      HubPoll(id: _uid(), roomId: roomId, creatorId: 'u2', question: 'Should we revise Unit 3 today?', yes: ['u2'], no: [], createdAt: _ago(1)),
    ];
    pinnedItems = [
      PinnedItem(id: _uid(), userId: 'u2', itemType: 'note', content: 'Exam on 25th April — Chapters 3-5 confirmed', label: '📌 Important', pinnedAt: _ago(0)),
    ];
    activities = [
      ActivityItem(id: _uid(), userId: userId, action: 'member_joined', metadata: {'userName': userName}, timestamp: _ago(5)),
      ActivityItem(id: _uid(), userId: 'u2', action: 'message_sent', metadata: {'preview': 'Hey! Should we start with Unit 3?'}, timestamp: _ago(3)),
      ActivityItem(id: _uid(), userId: 'u2', action: 'poll_created', metadata: {'question': 'Should we revise Unit 3 today?'}, timestamp: _ago(1)),
    ];
    docContent = '# Study Notes\n\n## Unit 3 – Deadlocks\n\n'
        'A deadlock occurs when two or more processes are waiting for each other...\n\n'
        'Four **Coffman conditions**:\n- Mutual Exclusion\n- Hold and Wait\n- No Preemption\n- Circular Wait\n';
    notifyListeners();
  }

  void _addDemoReply() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (currentRoom == null) return;
      final replies = ["Great point!", "Can someone explain this concept? 🤔", "I got it now, thanks!", "Break?"];
      messages.add(HubMessage(
        id: _uid(), roomId: currentRoom!.id, senderId: 'u2', senderName: 'Priya',
        content: replies[Random().nextInt(replies.length)], type: 'text',
        createdAt: DateTime.now().toIso8601String(), readBy: [],
      ));
      notifyListeners();
    });
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(999).toString();
  String _randomCode() => (100000 + Random().nextInt(899999)).toString().substring(0, 6).toUpperCase();
  String _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes)).toIso8601String();

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _sessionTimer?.cancel();
    _hubChannel?.unsubscribe();
    super.dispose();
  }
}
