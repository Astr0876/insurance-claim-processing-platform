import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:kanban_board/kanban_board.dart';

enum KanbanStatus { todo, doing, done }

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
  final _uuid = const Uuid();
  List<KanbanTask> _tasks = [];

  List<KanbanTask> get tasks => _tasks;

  List<KanbanTask> get todoTasks => _tasks.where((t) => t.status == KanbanStatus.todo).toList();
  List<KanbanTask> get doingTasks => _tasks.where((t) => t.status == KanbanStatus.doing).toList();
  List<KanbanTask> get doneTasks => _tasks.where((t) => t.status == KanbanStatus.done).toList();

  void loadDemoData() {
    final now = DateTime.now();
    _tasks = [
      KanbanTask(
        taskId: _uuid.v4(),
        title: 'Draft Project Proposal',
        description: 'Create the initial draft for the CS301 project.',
        assignee: 'Renee',
        assigneeAvatar: 'R',
        status: KanbanStatus.doing,
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 1)),
      ),
      KanbanTask(
        taskId: _uuid.v4(),
        title: 'Research UI Patterns',
        description: 'Look into neubrutalism design patterns for the app.',
        assignee: 'Alex',
        assigneeAvatar: 'A',
        status: KanbanStatus.todo,
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 3)),
      ),
      KanbanTask(
        taskId: _uuid.v4(),
        title: 'Database Schema Design',
        description: 'Define the ER diagram and tables.',
        assignee: 'Jordan',
        assigneeAvatar: 'J',
        status: KanbanStatus.todo,
        createdAt: now.subtract(const Duration(hours: 5)),
        dueDate: now.add(const Duration(days: 2)),
      ),
      KanbanTask(
        taskId: _uuid.v4(),
        title: 'Finalize Tech Stack',
        description: 'Choose between Flutter and React Native.',
        assignee: 'Renee',
        assigneeAvatar: 'R',
        status: KanbanStatus.done,
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.subtract(const Duration(days: 1)),
      ),
    ];
    notifyListeners();
  }

  void addTask({
    required String title,
    required String description,
    required String assignee,
    required String avatar,
    KanbanStatus status = KanbanStatus.todo,
    DateTime? dueDate,
  }) {
    final newTask = KanbanTask(
      taskId: _uuid.v4(),
      title: title,
      description: description,
      assignee: assignee,
      assigneeAvatar: avatar,
      status: status,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    _tasks.add(newTask);
    notifyListeners();
  }

  /// Triggers a final sync before power saving mode kicks in.
  Future<void> finalSync() async {
    debugPrint('BATTERY GUARDIAN: Triggering Final Kanban Sync...');
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('BATTERY GUARDIAN: Kanban Sync Complete.');
  }

  void updateTaskStatus(String taskId, KanbanStatus newStatus, {bool isRemote = false}) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final oldTask = _tasks[index];
      if (oldTask.status == newStatus) return;

      _tasks[index] = oldTask.copyWith(status: newStatus);
      
      // If it was a local move, we "broadcast" it to the Progress Engine
      if (!isRemote) {
        _broadcastToProgressEngine(taskId, newStatus);
      }
      
      notifyListeners();
    }
  }

  void _broadcastToProgressEngine(String taskId, KanbanStatus status) {
    // In a real app, this would send a socket event or HTTP request.
    // For testing/demo, we'll just log it.
    debugPrint('PROGRESS ENGINE: Task $taskId moved to $status');
  }

  /// Simulates a task being moved by another user (Global Reflection)
  void simulateRemoteMove(String taskId, KanbanStatus newStatus) {
    updateTaskStatus(taskId, newStatus, isRemote: true);
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }
}
