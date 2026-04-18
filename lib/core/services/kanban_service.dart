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

  void loadDemoData() {
    // Demo data logic can be kept for fallback or removed
    // For now, we'll just call fetchTasks if user is logged in
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

    final newTask = {
      'user_id': user.id,
      'title': title,
      'description': description,
      'assignee': assignee,
      'assignee_avatar': avatar,
      'status': status.toShortString(),
      'due_date': dueDate?.toIso8601String(),
    };

    try {
      final response = await _supabase.from('kanban_tasks').insert(newTask).select().single();
      _tasks.insert(0, KanbanTask.fromSupabase(response));
      notifyListeners();
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

      try {
        await _supabase
            .from('kanban_tasks')
            .update({'status': newStatus.toShortString()})
            .eq('id', taskId);

        _tasks[index] = oldTask.copyWith(status: newStatus);
        
        if (!isRemote) {
          debugPrint('PROGRESS ENGINE: Task $taskId moved to $newStatus');
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating task status: $e');
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
}
