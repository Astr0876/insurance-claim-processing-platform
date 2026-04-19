import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kanban_board/kanban_board.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/neubrut_tokens.dart';

enum KanbanStatus { todo, doing, done }

enum KanbanBoardVisibility { private, shared }

enum BoardTaskFilter { all, mine }

extension KanbanStatusExtension on KanbanStatus {
  String toShortString() => toString().split('.').last;

  static KanbanStatus fromString(String status) {
    return KanbanStatus.values.firstWhere(
      (e) => e.toShortString() == status,
      orElse: () => KanbanStatus.todo,
    );
  }
}

extension KanbanBoardVisibilityExtension on KanbanBoardVisibility {
  String toShortString() => toString().split('.').last;

  static KanbanBoardVisibility fromString(String visibility) {
    return KanbanBoardVisibility.values.firstWhere(
      (e) => e.toShortString() == visibility,
      orElse: () => KanbanBoardVisibility.private,
    );
  }
}

class KanbanBoard {
  final String id;
  final String ownerId;
  final String name;
  final KanbanBoardVisibility visibility;
  final bool isDefault;
  final DateTime createdAt;

  const KanbanBoard({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.visibility,
    required this.isDefault,
    required this.createdAt,
  });

  bool get isShared => visibility == KanbanBoardVisibility.shared;

  factory KanbanBoard.fromSupabase(Map<String, dynamic> map) {
    return KanbanBoard(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      visibility: KanbanBoardVisibilityExtension.fromString(
        (map['visibility'] ?? 'private') as String,
      ),
      isDefault: (map['is_default'] ?? false) as bool,
      createdAt: DateTime.parse(
        (map['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
    );
  }
}

class KanbanTask extends KanbanBoardGroupItem {
  final String taskId;
  final String boardId;
  final String userId;
  final String title;
  final String description;
  final String assignee;
  final String assigneeAvatar;
  final KanbanStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;

  KanbanTask({
    required this.taskId,
    required this.boardId,
    required this.userId,
    required this.title,
    required this.description,
    required this.assignee,
    required this.assigneeAvatar,
    required this.status,
    required this.createdAt,
    this.dueDate,
  });

  @override
  String get id => taskId;

  factory KanbanTask.fromSupabase(Map<String, dynamic> map) {
    return KanbanTask(
      taskId: map['id'] as String,
      boardId: (map['board_id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      assignee: (map['assignee'] ?? '') as String,
      assigneeAvatar: (map['assignee_avatar'] ?? '') as String,
      status: KanbanStatusExtension.fromString(
        (map['status'] ?? 'todo') as String,
      ),
      createdAt: DateTime.parse(
        (map['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
    );
  }

  KanbanTask copyWith({
    String? title,
    String? description,
    String? assignee,
    String? assigneeAvatar,
    KanbanStatus? status,
    DateTime? dueDate,
  }) {
    return KanbanTask(
      taskId: taskId,
      boardId: boardId,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      status: status ?? this.status,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class KanbanService extends ChangeNotifier {
  KanbanService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static const String _demoActorId = 'demo-me';

  List<KanbanBoard> _boards = [];
  String? _currentBoardId;
  BoardTaskFilter _taskFilter = BoardTaskFilter.all;
  final Map<String, List<KanbanTask>> _tasksByBoard = {};
  final Map<String, List<String>> _boardMembers = {};
  List<KanbanTask> _visibleTasks = [];
  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;

  List<KanbanBoard> get boards => _boards;
  String? get currentBoardId => _currentBoardId;
  KanbanBoard? get currentBoard {
    if (_currentBoardId == null) return null;
    final index = _boards.indexWhere((board) => board.id == _currentBoardId);
    if (index == -1) return null;
    return _boards[index];
  }

  BoardTaskFilter get taskFilter => _taskFilter;
  List<KanbanTask> get tasks => _visibleTasks;
  bool get isLoading => _isLoading;

  List<KanbanTask> tasksByStatus(KanbanStatus status) {
    return _visibleTasks.where((t) => t.status == status).toList();
  }

  List<KanbanTask> get todoTasks => tasksByStatus(KanbanStatus.todo);
  List<KanbanTask> get doingTasks => tasksByStatus(KanbanStatus.doing);
  List<KanbanTask> get doneTasks => tasksByStatus(KanbanStatus.done);

  List<KanbanTask> previewTasks(String boardId, {int limit = 3}) {
    final source = _tasksByBoard[boardId] ?? const <KanbanTask>[];
    return source.take(limit).toList();
  }

  int laneCount(String boardId, KanbanStatus status) {
    final source = _tasksByBoard[boardId] ?? const <KanbanTask>[];
    return source.where((task) => task.status == status).length;
  }

  List<String> boardMembers(String boardId) =>
      _boardMembers[boardId] ?? const <String>[];

  Future<void> fetchBoards() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _boards = [];
      _tasksByBoard.clear();
      _boardMembers.clear();
      _currentBoardId = null;
      _visibleTasks = [];
      loadDemoData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final ownBoards = await _supabase
          .from('kanban_boards')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: true);

      final membershipRows = await _supabase
          .from('kanban_board_members')
          .select('board_id')
          .eq('user_id', user.id);

      final memberBoardIds = (membershipRows as List)
          .map((row) => row['board_id'] as String)
          .toSet()
          .toList();

      List<dynamic> memberBoards = [];
      if (memberBoardIds.isNotEmpty) {
        memberBoards = await _supabase
            .from('kanban_boards')
            .select()
            .inFilter('id', memberBoardIds)
            .order('created_at', ascending: true);
      }

      final merged = <String, Map<String, dynamic>>{};
      for (final row in [...(ownBoards as List), ...memberBoards]) {
        merged[(row['id'] as String)] = Map<String, dynamic>.from(row as Map);
      }

      _boards =
          merged.values.map((row) => KanbanBoard.fromSupabase(row)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (_boards.isEmpty) {
        await _ensureDefaultBoard(user.id);
      }

      if (_currentBoardId == null ||
          !_boards.any((b) => b.id == _currentBoardId)) {
        _currentBoardId = _boards.isEmpty ? null : _boards.first.id;
      }

      await _loadBoardMemberships();
      await _hydrateBoardTaskSnapshots();
      _applyVisibleFilter();

      if (_currentBoardId != null) {
        subscribeToTasks(_currentBoardId!);
      }
    } catch (e) {
      debugPrint('Error fetching boards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureDefaultBoard(String userId) async {
    Map<String, dynamic> inserted;
    try {
      inserted = await _supabase
          .from('kanban_boards')
          .insert({
            'owner_id': userId,
            'name': 'My Board',
            'visibility': 'private',
            'is_default': true,
          })
          .select()
          .single();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final existing = await _supabase
            .from('kanban_boards')
            .select()
            .eq('owner_id', userId)
            .order('is_default', ascending: false)
            .order('created_at', ascending: true)
            .limit(1)
            .maybeSingle();
        if (existing == null) return;
        inserted = Map<String, dynamic>.from(existing);
      } else {
        rethrow;
      }
    }

    await _supabase.from('kanban_board_members').upsert({
      'board_id': inserted['id'],
      'user_id': userId,
      'role': 'owner',
    });

    _boards = [KanbanBoard.fromSupabase(inserted)];
    _currentBoardId = _boards.first.id;
  }

  Future<void> _loadBoardMemberships() async {
    if (_boards.isEmpty) return;

    final ids = _boards.map((b) => b.id).toList();
    final membershipRows = await _supabase
        .from('kanban_board_members')
        .select('board_id, user_id')
        .inFilter('board_id', ids);

    final byBoard = <String, List<String>>{};
    for (final row in membershipRows as List) {
      final boardId = row['board_id'] as String;
      final userId = row['user_id'] as String;
      byBoard.putIfAbsent(boardId, () => []);
      if (!byBoard[boardId]!.contains(userId)) {
        byBoard[boardId]!.add(userId);
      }
    }

    for (final board in _boards) {
      byBoard.putIfAbsent(board.id, () => []);
      if (!byBoard[board.id]!.contains(board.ownerId)) {
        byBoard[board.id]!.add(board.ownerId);
      }
    }

    _boardMembers
      ..clear()
      ..addAll(byBoard);
  }

  Future<void> _hydrateBoardTaskSnapshots() async {
    if (_boards.isEmpty) {
      _tasksByBoard.clear();
      _visibleTasks = [];
      return;
    }

    final ids = _boards.map((b) => b.id).toList();
    final rows = await _supabase
        .from('kanban_tasks')
        .select()
        .inFilter('board_id', ids)
        .order('created_at', ascending: false);

    _tasksByBoard
      ..clear()
      ..addEntries(ids.map((id) => MapEntry(id, <KanbanTask>[])));

    for (final row in rows as List) {
      final task = KanbanTask.fromSupabase(
        Map<String, dynamic>.from(row as Map),
      );
      _tasksByBoard.putIfAbsent(task.boardId, () => []);
      _tasksByBoard[task.boardId]!.add(task);
    }
  }

  Future<void> fetchTasks({String? boardId}) async {
    if (boardId != null) {
      _currentBoardId = boardId;
    }

    if (_supabase.auth.currentUser == null) {
      _applyVisibleFilter();
      notifyListeners();
      return;
    }

    if (_boards.isEmpty) {
      await fetchBoards();
      return;
    }

    await _hydrateBoardTaskSnapshots();
    _applyVisibleFilter();
    if (_currentBoardId != null) {
      subscribeToTasks(_currentBoardId!);
    }
    notifyListeners();
  }

  Future<void> selectBoard(String boardId) async {
    if (!_boards.any((board) => board.id == boardId)) {
      _currentBoardId = _boards.isEmpty ? null : _boards.first.id;
      _taskFilter = BoardTaskFilter.all;
      _applyVisibleFilter();
      notifyListeners();
      return;
    }
    if (boardId == _currentBoardId) return;
    _currentBoardId = boardId;
    _taskFilter = BoardTaskFilter.all;
    _applyVisibleFilter();

    if (_supabase.auth.currentUser != null) {
      subscribeToTasks(boardId);
    }

    notifyListeners();
  }

  Future<KanbanBoard?> createBoard({
    required String name,
    KanbanBoardVisibility visibility = KanbanBoardVisibility.private,
    List<String> memberUserIds = const [],
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    if (_boards.any(
      (board) => board.name.trim().toLowerCase() == cleanName.toLowerCase(),
    )) {
      return null;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      final localBoard = KanbanBoard(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        ownerId: _demoActorId,
        name: cleanName,
        visibility: visibility,
        isDefault: false,
        createdAt: DateTime.now(),
      );
      _boards = [..._boards, localBoard];
      _tasksByBoard.putIfAbsent(localBoard.id, () => []);
      _boardMembers[localBoard.id] = [_demoActorId, ...memberUserIds];
      _currentBoardId = localBoard.id;
      _applyVisibleFilter();
      notifyListeners();
      return localBoard;
    }

    try {
      final inserted = await _supabase
          .from('kanban_boards')
          .insert({
            'owner_id': user.id,
            'name': cleanName,
            'visibility': visibility.toShortString(),
            'is_default': false,
          })
          .select()
          .single();

      final board = KanbanBoard.fromSupabase(inserted);

      final memberships = <Map<String, dynamic>>[
        {'board_id': board.id, 'user_id': user.id, 'role': 'owner'},
      ];

      for (final memberId in memberUserIds.where((id) => id != user.id)) {
        memberships.add({
          'board_id': board.id,
          'user_id': memberId,
          'role': 'member',
        });
      }

      try {
        await _supabase.from('kanban_board_members').upsert(memberships);
      } catch (e) {
        await _supabase.from('kanban_boards').delete().eq('id', board.id);
        rethrow;
      }

      _boards = [..._boards, board]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _tasksByBoard.putIfAbsent(board.id, () => []);
      _boardMembers[board.id] = memberships
          .map((m) => m['user_id'] as String)
          .toSet()
          .toList();
      _currentBoardId = board.id;
      _taskFilter = BoardTaskFilter.all;
      _applyVisibleFilter();
      subscribeToTasks(board.id);
      notifyListeners();
      return board;
    } catch (e) {
      debugPrint('Error creating board: $e');
      return null;
    }
  }

  void setTaskFilter(BoardTaskFilter filter) {
    _taskFilter = filter;
    _applyVisibleFilter();
    notifyListeners();
  }

  void _applyVisibleFilter() {
    if (_currentBoardId == null) {
      _visibleTasks = [];
      return;
    }

    final boardTasks = List<KanbanTask>.from(
      _tasksByBoard[_currentBoardId] ?? const [],
    );
    if (_taskFilter == BoardTaskFilter.mine) {
      final actor = _supabase.auth.currentUser?.id ?? _demoActorId;
      _visibleTasks = boardTasks.where((task) => task.userId == actor).toList();
      return;
    }

    _visibleTasks = boardTasks;
  }

  Color resolveTaskColor(KanbanTask task, {KanbanBoard? board}) {
    final boardRef = board ?? currentBoard;
    if (boardRef == null ||
        boardRef.visibility == KanbanBoardVisibility.private) {
      return _colorForStatus(task.status);
    }

    final normalizedAssignee = task.assignee.trim().toLowerCase();
    final seed = normalizedAssignee.isNotEmpty
        ? normalizedAssignee
        : task.userId;
    if (seed.isEmpty) return NBColors.white;

    const palette = [
      NBColors.blue,
      NBColors.pink,
      NBColors.green,
      NBColors.purple,
      NBColors.orange,
      NBColors.primary,
    ];

    final hash = seed.codeUnits.fold<int>(
      0,
      (value, code) => value + code * 31,
    );
    final index = hash % palette.length;
    return palette[index];
  }

  Color _colorForStatus(KanbanStatus status) {
    switch (status) {
      case KanbanStatus.todo:
        return NBColors.blue;
      case KanbanStatus.doing:
        return NBColors.pink;
      case KanbanStatus.done:
        return NBColors.green;
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String assignee,
    required String avatar,
    KanbanStatus status = KanbanStatus.todo,
    DateTime? dueDate,
  }) async {
    final boardId = _currentBoardId;
    if (boardId == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      final localTask = KanbanTask(
        taskId: 'local-${DateTime.now().microsecondsSinceEpoch}',
        boardId: boardId,
        userId: _demoActorId,
        title: title,
        description: description,
        assignee: assignee,
        assigneeAvatar: avatar,
        status: status,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );
      _tasksByBoard.putIfAbsent(boardId, () => []);
      _tasksByBoard[boardId]!.insert(0, localTask);
      _applyVisibleFilter();
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase
          .from('kanban_tasks')
          .insert({
            'user_id': user.id,
            'board_id': boardId,
            'title': title,
            'description': description,
            'assignee': assignee,
            'assignee_avatar': avatar,
            'status': status.toShortString(),
            'due_date': dueDate?.toIso8601String(),
          })
          .select()
          .single();

      final newTask = KanbanTask.fromSupabase(response);
      _tasksByBoard.putIfAbsent(boardId, () => []);
      if (!_tasksByBoard[boardId]!.any(
        (task) => task.taskId == newTask.taskId,
      )) {
        _tasksByBoard[boardId]!.insert(0, newTask);
        _applyVisibleFilter();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> updateTaskStatus(
    String taskId,
    KanbanStatus newStatus, {
    bool isRemote = false,
    String? boardId,
  }) async {
    final effectiveBoardId = boardId ?? _currentBoardId;
    if (effectiveBoardId == null) return;

    final boardTasks = _tasksByBoard[effectiveBoardId];
    if (boardTasks == null) return;

    final index = boardTasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;

    final oldTask = boardTasks[index];
    if (oldTask.status == newStatus) return;

    final updatedTask = oldTask.copyWith(status: newStatus);
    boardTasks[index] = updatedTask;
    _applyVisibleFilter();
    notifyListeners();

    if (_supabase.auth.currentUser == null) {
      return;
    }

    if (!isRemote) {
      debugPrint(
        'PROGRESS ENGINE: Task $taskId moved to $newStatus (Optimistic)',
      );
    }

    try {
      await _supabase
          .from('kanban_tasks')
          .update({'status': newStatus.toShortString()})
          .eq('id', taskId);
    } catch (e) {
      debugPrint('Error updating task status: $e');
      final rollbackIndex = boardTasks.indexWhere((task) => task.id == taskId);
      if (rollbackIndex != -1) {
        boardTasks[rollbackIndex] = oldTask;
        _applyVisibleFilter();
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    final boardId = _currentBoardId;
    if (boardId == null) return;

    final boardTasks = _tasksByBoard[boardId];
    if (boardTasks == null) return;

    final oldTasks = List<KanbanTask>.from(boardTasks);
    boardTasks.removeWhere((task) => task.id == taskId);
    _applyVisibleFilter();
    notifyListeners();

    if (_supabase.auth.currentUser == null) return;

    try {
      await _supabase.from('kanban_tasks').delete().eq('id', taskId);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      _tasksByBoard[boardId] = oldTasks;
      _applyVisibleFilter();
      notifyListeners();
    }
  }

  void subscribeToTasks(String boardId) {
    if (_supabase.auth.currentUser == null) return;

    _tasksSubscription?.cancel();

    _tasksSubscription = _supabase
        .from('kanban_tasks')
        .stream(primaryKey: ['id'])
        .eq('board_id', boardId)
        .order('created_at', ascending: false)
        .listen(
          (List<Map<String, dynamic>> data) {
            _tasksByBoard[boardId] = data
                .map((row) => KanbanTask.fromSupabase(row))
                .toList();
            _applyVisibleFilter();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('PROGRESS ENGINE: Realtime Error: $error');
          },
        );
  }

  void loadDemoData() {
    _boards = [
      KanbanBoard(
        id: 'board-personal',
        ownerId: _demoActorId,
        name: 'Personal Focus',
        visibility: KanbanBoardVisibility.private,
        isDefault: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      KanbanBoard(
        id: 'board-shared',
        ownerId: _demoActorId,
        name: 'Squad Sprint',
        visibility: KanbanBoardVisibility.shared,
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _boardMembers
      ..clear()
      ..addAll({
        'board-personal': [_demoActorId],
        'board-shared': [_demoActorId, 'demo-teammate'],
      });

    _tasksByBoard
      ..clear()
      ..addAll({
        'board-personal': [
          KanbanTask(
            taskId: 'task-1',
            boardId: 'board-personal',
            userId: _demoActorId,
            title: 'Deep work block',
            description: '2 hours of focused revision.',
            assignee: 'You',
            assigneeAvatar: 'Y',
            status: KanbanStatus.todo,
            createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          ),
          KanbanTask(
            taskId: 'task-2',
            boardId: 'board-personal',
            userId: _demoActorId,
            title: 'Solve DSA set',
            description: 'Complete graph practice list.',
            assignee: 'You',
            assigneeAvatar: 'Y',
            status: KanbanStatus.doing,
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ],
        'board-shared': [
          KanbanTask(
            taskId: 'task-3',
            boardId: 'board-shared',
            userId: _demoActorId,
            title: 'Plan sprint board',
            description: 'Set priorities for release week.',
            assignee: 'You',
            assigneeAvatar: 'Y',
            status: KanbanStatus.todo,
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          KanbanTask(
            taskId: 'task-4',
            boardId: 'board-shared',
            userId: 'demo-teammate',
            title: 'Review PR checklist',
            description: 'Finalize QA checklist before merge.',
            assignee: 'Renee',
            assigneeAvatar: 'R',
            status: KanbanStatus.doing,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      });

    _currentBoardId = 'board-personal';
    _taskFilter = BoardTaskFilter.all;
    _isLoading = false;
    _applyVisibleFilter();
    notifyListeners();
  }

  Future<void> finalSync() async {
    await fetchBoards();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
