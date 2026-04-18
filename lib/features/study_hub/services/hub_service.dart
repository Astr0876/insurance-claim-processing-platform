// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/services/hub_service.dart
//  REST + Socket.io service for Collaborative Study Hub
//  Falls back to local simulation if server is unreachable.
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/hub_models.dart';

/// Change to your LAN/hosted IP when testing on a physical device
const String kServerBase = 'http://10.0.2.2:3000'; // emulator → localhost
// const String kServerBase = 'http://localhost:3000'; // web / desktop

class HubService extends ChangeNotifier {
  // ── Socket ───────────────────────────────────────────────────────
  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  // ── Identity (demo: no auth needed) ──────────────────────────────
  String userId   = 'user_${Random().nextInt(9999)}';
  String userName = 'Student';

  void setIdentity(String id, String name) {
    userId   = id;
    userName = name;
  }

  // ── State ─────────────────────────────────────────────────────────
  List<StudyRoom>   myRooms      = [];
  StudyRoom?        currentRoom;
  List<HubMessage>  messages     = [];
  List<PresenceInfo> presence    = [];
  List<HubPoll>     polls        = [];
  List<PinnedItem>  pinnedItems  = [];
  List<ActivityItem> activities  = [];
  StudySession?     studySession;
  String            docContent   = '';
  int               docVersion   = 0;

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
      _socket = IO.io(kServerBase, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build());

      _socket!.connect();
      _bindSocketEvents();

      // Heartbeat every 30s
      _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (currentRoom != null) {
          _socket?.emit('presence_ping', {
            'roomId': currentRoom!.id,
            'userId': userId,
            'status': 'active',
          });
        }
      });
    } catch (e) {
      debugPrint('HubService: socket connect error $e');
    }
  }

  void _bindSocketEvents() {
    _socket!.on('connect',    (_) { notifyListeners(); });
    _socket!.on('disconnect', (_) { notifyListeners(); });

    _socket!.on('room_state', (data) {
      messages    = _parseMessages(data['messages']);
      presence    = _parsePresence(data['presence']);
      polls       = _parsePolls(data['polls']);
      pinnedItems = _parsePins(data['pinnedItems']);
      activities  = _parseActivities(data['activity']);
      if (data['doc'] != null) {
        docContent = data['doc']['content'] ?? '';
        docVersion = data['doc']['version'] ?? 0;
      }
      if (data['studySession'] != null) {
        studySession = StudySession.fromJson(data['studySession']);
      }
      notifyListeners();
    });

    _socket!.on('receive_message', (data) {
      messages.add(HubMessage.fromJson(Map<String, dynamic>.from(data)));
      notifyListeners();
    });

    _socket!.on('typing', (data) {
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

    _socket!.on('presence_update', (data) {
      final list = data['presence'] as List;
      presence = list.map((p) => PresenceInfo.fromJson(Map<String, dynamic>.from(p))).toList();
      notifyListeners();
    });

    _socket!.on('doc_update', (data) {
      final incomingVersion = data['version'] ?? 0;
      if (incomingVersion >= docVersion) {
        docContent = data['content'] ?? '';
        docVersion = incomingVersion;
        notifyListeners();
      }
    });

    _socket!.on('poll_update', (data) {
      final poll = HubPoll.fromJson(Map<String, dynamic>.from(data['poll']));
      final idx  = polls.indexWhere((p) => p.id == poll.id);
      if (idx >= 0) polls[idx] = poll; else polls.add(poll);
      notifyListeners();
    });

    _socket!.on('pin_update', (data) {
      final pin = PinnedItem.fromJson(Map<String, dynamic>.from(data));
      pinnedItems.insert(0, pin);
      notifyListeners();
    });

    _socket!.on('session_update', (data) {
      if (data == null) {
        studySession = null;
        _sessionTimer?.cancel();
        _sessionTick = 0;
      } else {
        studySession = StudySession.fromJson(Map<String, dynamic>.from(data));
        _startSessionTick();
      }
      notifyListeners();
    });

    _socket!.on('activity_update', (data) {
      final item = ActivityItem.fromJson(Map<String, dynamic>.from(data));
      activities.insert(0, item);
      if (activities.length > 50) activities.removeLast();
      notifyListeners();
    });

    _socket!.on('read_receipt', (data) {
      final mid = data['messageId'] as String;
      final uid = data['userId'] as String;
      final msg = messages.firstWhere((m) => m.id == mid, orElse: () => messages.first);
      if (!msg.readBy.contains(uid)) msg.readBy.add(uid);
      notifyListeners();
    });
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

  Future<StudyRoom?> createRoom(String name) async {
    _isLoading = true; notifyListeners();
    errorMessage = null;
    try {
      final res = await http.post(
        Uri.parse('$kServerBase/rooms/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'ownerId': userId, 'ownerName': userName}),
      );
      if (res.statusCode == 200) {
        final room = StudyRoom.fromJson(jsonDecode(res.body)['room']);
        myRooms.add(room);
        _isLoading = false; notifyListeners();
        return room;
      }
    } catch (e) {
      // Demo fallback
      final room = _makeDemoRoom(name);
      myRooms.add(room);
      _isLoading = false; notifyListeners();
      return room;
    }
    _isLoading = false; notifyListeners();
    return null;
  }

  Future<StudyRoom?> joinRoom(String code) async {
    _isLoading = true; notifyListeners();
    errorMessage = null;
    try {
      final res = await http.post(
        Uri.parse('$kServerBase/rooms/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'userId': userId, 'userName': userName}),
      );
      if (res.statusCode == 200) {
        final room = StudyRoom.fromJson(jsonDecode(res.body)['room']);
        if (!myRooms.any((r) => r.id == room.id)) myRooms.add(room);
        _isLoading = false; notifyListeners();
        return room;
      } else {
        errorMessage = 'Room not found';
      }
    } catch (e) {
      errorMessage = 'Server unreachable';
    }
    _isLoading = false; notifyListeners();
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

    if (isConnected) {
      _socket?.emit('join_room', {
        'roomId': room.id,
        'userId': userId,
        'userName': userName,
      });
    } else {
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

  void sendMessage(String content, {String type = 'text'}) {
    if (currentRoom == null) return;
    final data = {
      'roomId': currentRoom!.id,
      'senderId': userId,
      'senderName': userName,
      'content': content,
      'type': type,
    };
    if (isConnected) {
      _socket?.emit('send_message', data);
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
    _socket?.emit('typing', {
      'roomId': currentRoom!.id,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
    });
  }

  // ─────────────────────────────────────────────────────────────────
  //  DOCUMENT
  // ─────────────────────────────────────────────────────────────────

  void updateDoc(String content) {
    docContent = content;
    docVersion++;
    if (currentRoom == null) return;
    if (isConnected) {
      _socket?.emit('doc_update', {
        'roomId': currentRoom!.id,
        'userId': userId,
        'content': content,
        'version': docVersion,
      });
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
      _socket?.emit('poll_create', {
        'roomId': currentRoom!.id,
        'creatorId': userId,
        'question': question,
      });
    }
  }

  void votePoll(String pollId, String vote) {
    final poll = polls.firstWhere((p) => p.id == pollId);
    poll.yes.remove(userId);
    poll.no.remove(userId);
    if (vote == 'yes') poll.yes.add(userId);
    else poll.no.add(userId);
    notifyListeners();

    if (isConnected) {
      _socket?.emit('poll_vote', {
        'roomId': currentRoom!.id,
        'pollId': pollId,
        'userId': userId,
        'vote': vote,
      });
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
      _socket?.emit('session_start', {'roomId': currentRoom!.id, 'userId': userId});
    }
  }

  void stopSession() {
    studySession = null;
    _sessionTimer?.cancel();
    _sessionTick = 0;
    notifyListeners();

    if (isConnected) {
      _socket?.emit('session_stop', {'roomId': currentRoom!.id, 'userId': userId});
    }
  }

  String get sessionDisplay {
    final m = _sessionTick ~/ 60;
    final s = _sessionTick % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────
  //  INSIGHTS (computed)
  // ─────────────────────────────────────────────────────────────────

  String get mostActiveUser {
    final counts = <String, int>{};
    for (final m in messages) { if (!m.isSystem) counts[m.senderName] = (counts[m.senderName] ?? 0) + 1; }
    if (counts.isEmpty) return '—';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int get totalMessages => messages.where((m) => !m.isSystem).length;

  // ─────────────────────────────────────────────────────────────────
  //  DEMO FALLBACK (when server is offline)
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
      final replies = [
        "Great point! Let me add that to the notes.",
        "Can someone explain this concept? 🤔",
        "I got it now, thanks!",
        "Should we take a 5-min break?",
        "Added to the pinned notes already.",
      ];
      messages.add(HubMessage(
        id: _uid(),
        roomId: currentRoom!.id,
        senderId: 'u2',
        senderName: 'Priya',
        content: replies[Random().nextInt(replies.length)],
        type: 'text',
        createdAt: DateTime.now().toIso8601String(),
        readBy: [],
      ));
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────

  List<HubMessage>  _parseMessages(dynamic data)    => (data as List? ?? []).map((e) => HubMessage.fromJson(Map<String, dynamic>.from(e))).toList();
  List<PresenceInfo> _parsePresence(dynamic data)   => (data as List? ?? []).map((e) => PresenceInfo.fromJson(Map<String, dynamic>.from(e))).toList();
  List<HubPoll>     _parsePolls(dynamic data)       => (data as List? ?? []).map((e) => HubPoll.fromJson(Map<String, dynamic>.from(e))).toList();
  List<PinnedItem>  _parsePins(dynamic data)        => (data as List? ?? []).map((e) => PinnedItem.fromJson(Map<String, dynamic>.from(e))).toList();
  List<ActivityItem> _parseActivities(dynamic data) => (data as List? ?? []).map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e))).toList();

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(999).toString();
  String _randomCode() => (100000 + Random().nextInt(899999)).toString().substring(0, 6).toUpperCase();
  String _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes)).toIso8601String();

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _sessionTimer?.cancel();
    _socket?.disconnect();
    super.dispose();
  }
}
