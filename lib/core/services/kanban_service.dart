import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanban_board/kanban_board.dart';

enum KanbanStatus { todo, doing, done }

extension KanbanStatusExtension on KanbanStatus {
  String toShortString() => toString().split('.').last;
  static KanbanStatus fromString(String status) {
    return KanbanStatus.values.firstWhere(
      (e) => e.toShortString() == status,
      orElse: () => KanbanStatus.todo,
    );
  }
}

class KanbanTask extends KanbanBoardGroupItem {
  final String taskId;
  final String title;
  final String description;
  final String assignee;
  final String assigneeAvatar;
  final KanbanStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;

  KanbanTask({
    required this.taskId,
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
      taskId: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      assignee: map['assignee'] ?? '',
      assigneeAvatar: map['assignee_avatar'] ?? '',
      status: KanbanStatusExtension.fromString(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'assignee': assignee,
      'assignee_avatar': assigneeAvatar,
      'status': status.toShortString(),
      'due_date': dueDate?.toIso8601String(),
    };
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
  final _supabase = Supabase.instance.client;
  List<KanbanTask> _tasks = [];
  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;

  List<KanbanTask> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<KanbanTask> get todoTasks => _tasks.where((t) => t.status == KanbanStatus.todo).toList();
  List<KanbanTask> get doingTasks => _tasks.where((t) => t.status == KanbanStatus.doing).toList();
  List<KanbanTask> get doneTasks => _tasks.where((t) => t.status == KanbanStatus.done).toList();

  Future<void> fetchTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    // Start real-time subscription
    subscribeToTasks();

    try {
      final response = await _supabase
          .from('kanban_tasks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _tasks = (response as List).map((t) => KanbanTask.fromSupabase(t)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToTasks() {
    final user = _supabase.auth.currentUser;
    if (user == null || _tasksSubscription != null) return;

    debugPrint('PROGRESS ENGINE: Subscribing to Kanban Realtime Updates...');
    
    _tasksSubscription = _supabase
        .from('kanban_tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          _tasks = data.map((t) => KanbanTask.fromSupabase(t)).toList();
          notifyListeners();
          debugPrint('PROGRESS ENGINE: Received ${data.length} tasks from remote.');
        }, onError: (error) {
          debugPrint('PROGRESS ENGINE: Realtime Error: $error');
        });
  }

  void loadDemoData() {
    fetchTasks();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String assignee,
    required String avatar,
    KanbanStatus status = KanbanStatus.todo,
    DateTime? dueDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newTaskData = {
      'user_id': user.id,
      'title': title,
      'description': description,
      'assignee': assignee,
      'assignee_avatar': avatar,
      'status': status.toShortString(),
      'due_date': dueDate?.toIso8601String(),
    };

    try {
      // Optimistic local add (optional, but good for UX)
      // Since stream will catch the insert, we might skip manual list management here
      // but let's do a simple optimistic insert for instant feel.
      // However, we don't have the ID yet. 
      // Supabase's insert with .select().single() is fast enough.
      
      final response = await _supabase.from('kanban_tasks').insert(newTaskData).select().single();
      // We don't strictly need to add to _tasks manually if stream is active, 
      // but it helps if stream is slow.
      final newTask = KanbanTask.fromSupabase(response);
      if (!_tasks.any((t) => t.taskId == newTask.taskId)) {
        _tasks.insert(0, newTask);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> finalSync() async {
    debugPrint('BATTERY GUARDIAN: Triggering Kanban Sync...');
    await fetchTasks();
    debugPrint('BATTERY GUARDIAN: Kanban Sync Complete.');
  }

  Future<void> updateTaskStatus(String taskId, KanbanStatus newStatus, {bool isRemote = false}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final oldTask = _tasks[index];
      if (oldTask.status == newStatus) return;

      // --- OPTIMISTIC UPDATE (Offline Graceful Handling) ---
      final updatedTask = oldTask.copyWith(status: newStatus);
      _tasks[index] = updatedTask;
      notifyListeners();
      
      if (!isRemote) {
        debugPrint('PROGRESS ENGINE: Task $taskId moved to $newStatus (Optimistic)');
      }

      try {
        await _supabase
            .from('kanban_tasks')
            .update({'status': newStatus.toShortString()})
            .eq('id', taskId);
        
        // Success: State is already correct due to optimism.
      } catch (e) {
        debugPrint('Error updating task status: $e');
        
        // --- ROLLBACK (Offline Recovery) ---
        // If the update fails (e.g. offline), we revert to the old status
        // and notify listeners so the UI snaps back.
        final reIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (reIndex != -1) {
          _tasks[reIndex] = oldTask;
          notifyListeners();
        }
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('kanban_tasks').delete().eq('id', taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}

