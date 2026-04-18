import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanban_board/kanban_board.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/kanban_service.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_button.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final KanbanBoardController _controller = KanbanBoardController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final kanban = appState.kanban;

    // Define groups based on KanbanStatus
    final List<KanbanBoardGroup<String, KanbanTask>> groups = [
      KanbanBoardGroup(
        id: 'todo',
        name: 'WHAT I WANT TO DO',
        items: kanban.todoTasks,
      ),
      KanbanBoardGroup(
        id: 'doing',
        name: 'WHAT I AM DOING',
        items: kanban.doingTasks,
      ),
      KanbanBoardGroup(
        id: 'done',
        name: 'COMPLETED',
        items: kanban.doneTasks,
      ),
    ];

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        backgroundColor: NBColors.bg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'PROGRESS ENGINE',
          style: NBText.heading2.copyWith(letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: NBColors.black, size: 28),
            onPressed: () => _showAddTaskDialog(context, kanban),
          ),
          const SizedBox(width: NBSpacing.sm),
        ],
      ),
      body: KanbanBoard(
        controller: _controller,
        groups: groups,
        onGroupItemMove: (oldGroupId, oldItemIndex, newGroupId, newItemIndex) {
          final String taskId;
          final KanbanStatus newStatus;

          if (oldGroupId is int) {
            taskId = groups[oldGroupId].items[oldItemIndex].taskId;
          } else {
            final group = groups.firstWhere((g) => g.id == oldGroupId.toString());
            taskId = group.items[oldItemIndex].taskId;
          }

          if (newGroupId is int) {
            newStatus = _statusFromGroupIndex(newGroupId);
          } else {
            newStatus = _statusFromGroupId(newGroupId.toString());
          }

          kanban.updateTaskStatus(taskId, newStatus);
        },
        groupHeaderBuilder: (context, groupId) {
          final KanbanBoardGroup<String, KanbanTask> group;
          if (groupId is int) {
            group = groups[groupId as int];
          } else {
            group = groups.firstWhere((g) => g.id == groupId.toString());
          }
          
          return Padding(
            padding: const EdgeInsets.all(NBSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _colorForStatus(group.id),
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
                boxShadow: NBShadows.small,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.name.toUpperCase(),
                    style: NBText.label.copyWith(fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: NBColors.white,
                      border: Border.all(color: NBColors.black, width: 1.5),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text(
                      group.items.length.toString(),
                      style: NBText.monoSmall.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        groupItemBuilder: (context, groupId, itemIndex) {
          final KanbanBoardGroup<String, KanbanTask> group;
          if (groupId is int) {
            group = groups[groupId as int];
          } else {
            group = groups.firstWhere((g) => g.id == groupId.toString());
          }
          final task = group.items[itemIndex];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: NBSpacing.md, vertical: NBSpacing.xs),
            child: NBCard(
              padding: const EdgeInsets.all(NBSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: NBText.heading3.copyWith(fontSize: 16),
                        ),
                      ),
                      _buildAssigneeBadge(task.assigneeAvatar, task.assignee),
                    ],
                  ),
                  const SizedBox(height: NBSpacing.xs),
                  Text(
                    task.description,
                    style: NBText.bodySmall.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssigneeBadge(String avatar, String name) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: NBColors.primary,
        border: Border.all(color: NBColors.black, width: 1.5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        avatar,
        style: NBText.label.copyWith(fontSize: 10),
      ),
    );
  }

  Color _colorForStatus(String groupId) {
    switch (groupId) {
      case 'todo': return NBColors.blue;
      case 'doing': return NBColors.pink;
      case 'done': return NBColors.green;
      default: return NBColors.primary;
    }
  }

  KanbanStatus _statusFromGroupIndex(int index) {
    switch (index) {
      case 0: return KanbanStatus.todo;
      case 1: return KanbanStatus.doing;
      case 2: return KanbanStatus.done;
      default: return KanbanStatus.todo;
    }
  }

  KanbanStatus _statusFromGroupId(String id) {
    switch (id) {
      case 'todo': return KanbanStatus.todo;
      case 'doing': return KanbanStatus.doing;
      case 'done': return KanbanStatus.done;
      default: return KanbanStatus.todo;
    }
  }

  void _showAddTaskDialog(BuildContext context, KanbanService kanban) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NBColors.bg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: NBColors.black, width: 3),
          borderRadius: NBRadius.softAll,
        ),
        title: Text('NEW TASK', style: NBText.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(titleController, 'Title'),
            const SizedBox(height: NBSpacing.md),
            _buildTextField(descController, 'Description', maxLines: 3),
          ],
        ),
        actions: [
          NBButton(
            label: 'Cancel',
            fillColor: NBColors.white,
            onTap: () => Navigator.pop(context),
          ),
          NBButton(
            label: 'Add',
            onTap: () {
              if (titleController.text.isNotEmpty) {
                kanban.addTask(
                  title: titleController.text,
                  description: descController.text,
                  assignee: 'Renee',
                  avatar: 'R',
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: NBColors.white,
        border: Border.all(color: NBColors.black, width: 2),
        borderRadius: NBRadius.softAll,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: NBText.bodySmall,
        ),
      ),
    );
  }
}
