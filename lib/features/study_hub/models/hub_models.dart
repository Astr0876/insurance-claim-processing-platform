// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/models/hub_models.dart
//  All data models for the Collaborative Study Hub
// ─────────────────────────────────────────────────────────────────

class RoomMember {
  final String userId;
  final String name;
  final String role; // admin | editor | viewer
  final String joinedAt;

  RoomMember({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory RoomMember.fromJson(Map<String, dynamic> j) => RoomMember(
        userId: j['userId'] ?? '',
        name: j['name'] ?? 'User',
        role: j['role'] ?? 'viewer',
        joinedAt: j['joinedAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'role': role,
        'joinedAt': joinedAt,
      };
}

class StudyRoom {
  final String id;
  final String name;
  final String ownerId;
  final List<RoomMember> members;
  final String code;
  final String createdAt;

  StudyRoom({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.code,
    required this.createdAt,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> j) => StudyRoom(
        id: j['id'] ?? '',
        name: j['name'] ?? 'Room',
        ownerId: j['ownerId'] ?? '',
        members: (j['members'] as List? ?? [])
            .map((m) => RoomMember.fromJson(m))
            .toList(),
        code: j['code'] ?? '',
        createdAt: j['createdAt'] ?? '',
      );

  bool isAdmin(String userId) =>
      members.any((m) => m.userId == userId && m.role == 'admin');
  bool canEdit(String userId) =>
      members.any((m) => m.userId == userId && (m.role == 'admin' || m.role == 'editor'));
}

class HubMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // text | system | file
  final String createdAt;
  final List<String> readBy;

  HubMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.readBy,
  });

  factory HubMessage.fromJson(Map<String, dynamic> j) => HubMessage(
        id: j['id'] ?? '',
        roomId: j['roomId'] ?? '',
        senderId: j['senderId'] ?? '',
        senderName: j['senderName'] ?? 'User',
        content: j['content'] ?? '',
        type: j['type'] ?? 'text',
        createdAt: j['createdAt'] ?? '',
        readBy: List<String>.from(j['readBy'] ?? []),
      );

  bool get isSystem => type == 'system';
}

class PresenceInfo {
  final String userId;
  final String userName;
  String status; // active | idle | offline
  String lastSeen;

  PresenceInfo({
    required this.userId,
    required this.userName,
    required this.status,
    required this.lastSeen,
  });

  factory PresenceInfo.fromJson(Map<String, dynamic> j) => PresenceInfo(
        userId: j['userId'] ?? '',
        userName: j['userName'] ?? 'User',
        status: j['status'] ?? 'offline',
        lastSeen: j['lastSeen'] ?? '',
      );
}

class HubPoll {
  final String id;
  final String roomId;
  final String creatorId;
  final String question;
  List<String> yes;
  List<String> no;
  final String createdAt;

  HubPoll({
    required this.id,
    required this.roomId,
    required this.creatorId,
    required this.question,
    required this.yes,
    required this.no,
    required this.createdAt,
  });

  factory HubPoll.fromJson(Map<String, dynamic> j) => HubPoll(
        id: j['id'] ?? '',
        roomId: j['roomId'] ?? '',
        creatorId: j['creatorId'] ?? '',
        question: j['question'] ?? '',
        yes: List<String>.from(j['yes'] ?? []),
        no: List<String>.from(j['no'] ?? []),
        createdAt: j['createdAt'] ?? '',
      );

  int get totalVotes => yes.length + no.length;
  bool hasVoted(String userId) => yes.contains(userId) || no.contains(userId);
}

class PinnedItem {
  final String id;
  final String userId;
  final String itemType; // message | note | file
  final String content;
  final String label;
  final String pinnedAt;

  PinnedItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.content,
    required this.label,
    required this.pinnedAt,
  });

  factory PinnedItem.fromJson(Map<String, dynamic> j) => PinnedItem(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        itemType: j['itemType'] ?? 'note',
        content: j['content'] ?? '',
        label: j['label'] ?? 'Note',
        pinnedAt: j['pinnedAt'] ?? '',
      );
}

class ActivityItem {
  final String id;
  final String userId;
  final String action;
  final Map<String, dynamic> metadata;
  final String timestamp;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.action,
    required this.metadata,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        action: j['action'] ?? '',
        metadata: Map<String, dynamic>.from(j['metadata'] ?? {}),
        timestamp: j['timestamp'] ?? '',
      );

  String get description {
    switch (action) {
      case 'member_joined': return '${metadata['userName'] ?? 'User'} joined the room';
      case 'message_sent':  return 'Message: "${metadata['preview'] ?? ''}"';
      case 'doc_edited':    return 'Document updated';
      case 'poll_created':  return 'Poll: "${metadata['question'] ?? ''}"';
      case 'item_pinned':   return 'Pinned: ${metadata['label'] ?? ''}';
      case 'session_started': return 'Study session started';
      case 'room_created':  return 'Room created: ${metadata['roomName'] ?? ''}';
      default: return action;
    }
  }

  String get icon {
    switch (action) {
      case 'member_joined':   return '👋';
      case 'message_sent':    return '💬';
      case 'doc_edited':      return '📝';
      case 'poll_created':    return '🗳️';
      case 'item_pinned':     return '📌';
      case 'session_started': return '⏱️';
      case 'room_created':    return '🏠';
      default: return '📌';
    }
  }
}

class StudySession {
  final String roomId;
  final String startedBy;
  final String startedAt;
  final List<String> activeUsers;

  StudySession({
    required this.roomId,
    required this.startedBy,
    required this.startedAt,
    required this.activeUsers,
  });

  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
        roomId: j['roomId'] ?? '',
        startedBy: j['startedBy'] ?? '',
        startedAt: j['startedAt'] ?? '',
        activeUsers: List<String>.from(j['activeUsers'] ?? []),
      );

  Duration get elapsed => DateTime.now().difference(DateTime.tryParse(startedAt) ?? DateTime.now());
  String get elapsedFormatted {
    final d = elapsed;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${d.inMinutes}m';
  }
}
