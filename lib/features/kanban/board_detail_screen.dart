import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../core/services/kanban_service.dart';
import '../../core/theme/neubrut_tokens.dart';

class BoardDetailScreen extends StatefulWidget {
  const BoardDetailScreen({
    super.key,
    required this.boardId,
    this.kanbanService,
  });

  final String boardId;
  final KanbanService? kanbanService;

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kanban = _readKanban(context);
      kanban.selectBoard(widget.boardId);
      kanban.fetchTasks(boardId: widget.boardId);
    });
  }

  KanbanService _readKanban(BuildContext context) {
    if (widget.kanbanService != null) return widget.kanbanService!;

    try {
      return Provider.of<AppState>(context, listen: false).kanban;
    } catch (_) {
      return Provider.of<KanbanService>(context, listen: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kanbanService != null) {
      return AnimatedBuilder(
        animation: widget.kanbanService!,
        builder: (context, _) => _buildDetail(context, widget.kanbanService!),
      );
    }

    try {
      final kanban = context.watch<AppState>().kanban;
      return _buildDetail(context, kanban);
    } catch (_) {
      final kanban = context.watch<KanbanService>();
      return _buildDetail(context, kanban);
    }
  }

  Widget _buildDetail(BuildContext context, KanbanService kanban) {
    final boardIndex = kanban.boards.indexWhere((b) => b.id == widget.boardId);
    final board = boardIndex == -1 ? null : kanban.boards[boardIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF191825),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191825),
        foregroundColor: NBColors.white,
        title: Text(
          board?.name ?? 'BOARD',
          style: NBText.heading3.copyWith(color: NBColors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(NBSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: NBSpacing.md,
              vertical: NBSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2A45),
              border: Border.all(color: NBColors.white, width: 1.5),
              borderRadius: NBRadius.softAll,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: NBColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LIVE ACTIVITY • Task transitions and updates syncing now',
                    style: NBText.bodySmall.copyWith(color: NBColors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NBSpacing.md),
            child: Row(
              children: [
                _filterChip(
                  key: const Key('filter-all'),
                  label: 'ALL TASKS',
                  selected: kanban.taskFilter == BoardTaskFilter.all,
                  onTap: () => kanban.setTaskFilter(BoardTaskFilter.all),
                ),
                const SizedBox(width: NBSpacing.sm),
                _filterChip(
                  key: const Key('filter-mine'),
                  label: 'MY TASKS',
                  selected: kanban.taskFilter == BoardTaskFilter.mine,
                  onTap: () => kanban.setTaskFilter(BoardTaskFilter.mine),
                ),
                const SizedBox(width: NBSpacing.sm),
                Expanded(
                  child: Text(
                    board?.isShared == true
                        ? 'ASSIGNEE COLORS ACTIVE'
                        : 'STATUS COLORS ACTIVE',
                    key: const Key('color-rule-indicator'),
                    textAlign: TextAlign.right,
                    style: NBText.label.copyWith(
                      color: NBColors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NBSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NBSpacing.md,
                0,
                NBSpacing.md,
                NBSpacing.md,
              ),
              child: Row(
                children: [
                  _laneColumn(context, kanban, board, KanbanStatus.todo),
                  const SizedBox(width: NBSpacing.sm),
                  _laneColumn(context, kanban, board, KanbanStatus.doing),
                  const SizedBox(width: NBSpacing.sm),
                  _laneColumn(context, kanban, board, KanbanStatus.done),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NBColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: NBRadius.softAll,
          side: const BorderSide(color: NBColors.black, width: 2),
        ),
        onPressed: () => _showAddTaskDialog(context, kanban),
        child: const Icon(Icons.add, color: NBColors.black),
      ),
    );
  }

  Widget _laneColumn(
    BuildContext context,
    KanbanService kanban,
    KanbanBoard? board,
    KanbanStatus status,
  ) {
    final tasks = kanban.tasksByStatus(status);

    return Expanded(
      child: DragTarget<KanbanTask>(
        onWillAcceptWithDetails: (details) =>
            details.data.status != status &&
            details.data.boardId == widget.boardId,
        onAcceptWithDetails: (details) {
          kanban.updateTaskStatus(
            details.data.taskId,
            status,
            boardId: details.data.boardId,
          );
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            padding: const EdgeInsets.all(NBSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF25223A),
              borderRadius: NBRadius.softAll,
              border: Border.all(color: NBColors.white, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _laneName(status),
                        style: NBText.label.copyWith(color: NBColors.white),
                      ),
                    ),
                    Text(
                      '${tasks.length}',
                      style: NBText.monoSmall.copyWith(color: NBColors.white),
                    ),
                  ],
                ),
                const SizedBox(height: NBSpacing.sm),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'Drop here',
                            style: NBText.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: NBSpacing.sm),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final card = Container(
                              padding: const EdgeInsets.all(NBSpacing.sm),
                              decoration: BoxDecoration(
                                color: kanban.resolveTaskColor(
                                  task,
                                  board: board,
                                ),
                                borderRadius: NBRadius.softAll,
                                border: Border.all(
                                  color: NBColors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.title, style: NBText.label),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description,
                                    style: NBText.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Assignee: ${task.assignee.isEmpty ? 'Unassigned' : task.assignee}',
                                    style: NBText.monoSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status != KanbanStatus.todo)
                                        _moveButton(
                                          Icons.arrow_back_ios_new_rounded,
                                          () => kanban.updateTaskStatus(
                                            task.taskId,
                                            _previous(status),
                                            boardId: task.boardId,
                                          ),
                                        ),
                                      if (status != KanbanStatus.done) ...[
                                        const SizedBox(width: 6),
                                        _moveButton(
                                          Icons.arrow_forward_ios_rounded,
                                          () => kanban.updateTaskStatus(
                                            task.taskId,
                                            _next(status),
                                            boardId: task.boardId,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );

                            return LongPressDraggable<KanbanTask>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(width: 180, child: card),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.4,
                                child: card,
                              ),
                              child: card,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _moveButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: NBColors.white,
          border: Border.all(color: NBColors.black, width: 1.5),
          borderRadius: NBRadius.softAll,
        ),
        child: Icon(icon, size: 12, color: NBColors.black),
      ),
    );
  }

  Widget _filterChip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NBColors.primary : const Color(0xFF2D2A45),
          borderRadius: NBRadius.softAll,
          border: Border.all(
            color: selected ? NBColors.black : NBColors.white,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: NBText.label.copyWith(
            color: selected ? NBColors.black : NBColors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  KanbanStatus _next(KanbanStatus status) {
    if (status == KanbanStatus.todo) return KanbanStatus.doing;
    return KanbanStatus.done;
  }

  KanbanStatus _previous(KanbanStatus status) {
    if (status == KanbanStatus.done) return KanbanStatus.doing;
    return KanbanStatus.todo;
  }

  String _laneName(KanbanStatus status) {
    switch (status) {
      case KanbanStatus.todo:
        return 'TODO';
      case KanbanStatus.doing:
        return 'DOING';
      case KanbanStatus.done:
        return 'DONE';
    }
  }

  void _showAddTaskDialog(BuildContext context, KanbanService kanban) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NBColors.bg,
        title: Text('ADD TASK', style: NBText.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              kanban.addTask(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                assignee: 'You',
                avatar: 'Y',
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
