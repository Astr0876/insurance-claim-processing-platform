import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../core/services/kanban_service.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_button.dart';
import '../../core/widgets/nb_card.dart';
import 'board_detail_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key, this.kanbanService});

  final KanbanService? kanbanService;

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kanban = _readKanban(context);
      if (kanban.boards.isEmpty) {
        kanban.fetchBoards();
      }
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
        builder: (context, _) => _buildHub(context, widget.kanbanService!),
      );
    }

    try {
      final kanban = context.watch<AppState>().kanban;
      return _buildHub(context, kanban);
    } catch (_) {
      final kanban = context.watch<KanbanService>();
      return _buildHub(context, kanban);
    }
  }

  Widget _buildHub(BuildContext context, KanbanService kanban) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 20),
            const SizedBox(width: 8),
            Text('KANBAN HUB', style: NBText.heading3),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(NBSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'MULTI-BOARD WORKSPACE',
                    style: NBText.label.copyWith(fontSize: 11),
                  ),
                ),
                NBButton(
                  label: 'Filter',
                  fillColor: NBColors.white,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: kanban.isLoading && kanban.boards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      NBSpacing.md,
                      0,
                      NBSpacing.md,
                      NBSpacing.xl,
                    ),
                    itemCount: kanban.boards.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: NBSpacing.md),
                    itemBuilder: (context, index) {
                      final board = kanban.boards[index];
                      return NBCard(
                        key: Key('board-card-${board.id}'),
                        onTap: () async {
                          await kanban.selectBoard(board.id);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BoardDetailScreen(
                                boardId: board.id,
                                kanbanService: kanban,
                              ),
                            ),
                          );
                        },
                        fillColor: board.isShared
                            ? NBColors.purple
                            : NBColors.white,
                        shadows: NBShadows.small,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    board.name,
                                    style: NBText.heading3.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: board.isShared
                                        ? NBColors.orange
                                        : NBColors.blue,
                                    border: Border.all(
                                      color: NBColors.black,
                                      width: 1.5,
                                    ),
                                    borderRadius: NBRadius.softAll,
                                  ),
                                  child: Text(
                                    board.isShared ? 'SHARED' : 'PRIVATE',
                                    style: NBText.label.copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NBSpacing.sm),
                            Row(
                              children: [
                                _lanePreviewChip(
                                  'TODO',
                                  kanban.laneCount(board.id, KanbanStatus.todo),
                                  NBColors.blue,
                                ),
                                const SizedBox(width: NBSpacing.sm),
                                _lanePreviewChip(
                                  'DOING',
                                  kanban.laneCount(
                                    board.id,
                                    KanbanStatus.doing,
                                  ),
                                  NBColors.pink,
                                ),
                                const SizedBox(width: NBSpacing.sm),
                                _lanePreviewChip(
                                  'DONE',
                                  kanban.laneCount(board.id, KanbanStatus.done),
                                  NBColors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: NBSpacing.sm),
                            Wrap(
                              spacing: NBSpacing.xs,
                              runSpacing: NBSpacing.xs,
                              children: kanban
                                  .previewTasks(board.id, limit: 2)
                                  .map(
                                    (task) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kanban.resolveTaskColor(
                                          task,
                                          board: board,
                                        ),
                                        border: Border.all(
                                          color: NBColors.black,
                                          width: 1.5,
                                        ),
                                        borderRadius: NBRadius.softAll,
                                      ),
                                      child: Text(
                                        task.title,
                                        style: NBText.bodySmall,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: NBColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: NBRadius.softAll,
          side: const BorderSide(color: NBColors.black, width: 2),
        ),
        onPressed: () => _showCreateBoardDialog(context, kanban),
        label: Text('CREATE BOARD', style: NBText.label),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _lanePreviewChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: NBColors.black, width: 1.5),
          borderRadius: NBRadius.softAll,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: NBText.label.copyWith(fontSize: 10)),
            Text('$count', style: NBText.monoSmall),
          ],
        ),
      ),
    );
  }

  void _showCreateBoardDialog(BuildContext context, KanbanService kanban) {
    final nameController = TextEditingController();
    final membersController = TextEditingController();
    KanbanBoardVisibility visibility = KanbanBoardVisibility.private;
    String? errorText;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: NBColors.bg,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: NBColors.black, width: 3),
            borderRadius: NBRadius.softAll,
          ),
          title: Text('CREATE BOARD', style: NBText.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Board name',
                  errorText: errorText,
                  labelStyle: NBText.bodySmall,
                  filled: true,
                  fillColor: NBColors.white,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: NBColors.black,
                      width: 2,
                    ),
                    borderRadius: NBRadius.softAll,
                  ),
                ),
              ),
              const SizedBox(height: NBSpacing.md),
              if (visibility == KanbanBoardVisibility.shared) ...[
                TextField(
                  controller: membersController,
                  decoration: InputDecoration(
                    labelText: 'Member user IDs (comma-separated)',
                    labelStyle: NBText.bodySmall,
                    filled: true,
                    fillColor: NBColors.white,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: NBColors.black,
                        width: 2,
                      ),
                      borderRadius: NBRadius.softAll,
                    ),
                  ),
                ),
                const SizedBox(height: NBSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: NBButton(
                      label: 'Private',
                      fillColor: visibility == KanbanBoardVisibility.private
                          ? NBColors.blue
                          : NBColors.white,
                      onTap: () => setState(
                        () => visibility = KanbanBoardVisibility.private,
                      ),
                    ),
                  ),
                  const SizedBox(width: NBSpacing.sm),
                  Expanded(
                    child: NBButton(
                      label: 'Shared',
                      fillColor: visibility == KanbanBoardVisibility.shared
                          ? NBColors.purple
                          : NBColors.white,
                      onTap: () => setState(
                        () => visibility = KanbanBoardVisibility.shared,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            NBButton(
              label: 'Cancel',
              fillColor: NBColors.white,
              onTap: () => Navigator.pop(context),
            ),
            NBButton(
              label: 'Create',
              onTap: () async {
                final cleanName = nameController.text.trim();
                if (cleanName.isEmpty) {
                  setState(() => errorText = 'Board name is required');
                  return;
                }
                if (kanban.boards.any(
                  (board) =>
                      board.name.trim().toLowerCase() ==
                      cleanName.toLowerCase(),
                )) {
                  setState(
                    () => errorText = 'A board with this name already exists',
                  );
                  return;
                }

                final memberIds = membersController.text
                    .split(',')
                    .map((id) => id.trim())
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();
                if (visibility == KanbanBoardVisibility.shared &&
                    memberIds.isEmpty) {
                  setState(
                    () => errorText =
                        'Add at least one member ID for shared boards',
                  );
                  return;
                }

                final board = await kanban.createBoard(
                  name: cleanName,
                  visibility: visibility,
                  memberUserIds: memberIds,
                );
                if (!context.mounted) return;
                if (board == null) {
                  setState(
                    () =>
                        errorText = 'Unable to create board. Please try again.',
                  );
                  return;
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BoardDetailScreen(
                      boardId: board.id,
                      kanbanService: kanban,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
