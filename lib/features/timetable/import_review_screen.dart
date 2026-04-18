import 'package:flutter/material.dart';

import '../../core/services/timetable_service.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_button.dart';
import '../../core/widgets/nb_card.dart';

class TimetableImportReviewScreen extends StatefulWidget {
  final List<ParsedClassSlot> initialSlots;
  final List<ParseIssue> issues;
  final String rawText;

  const TimetableImportReviewScreen({
    super.key,
    required this.initialSlots,
    required this.issues,
    required this.rawText,
  });

  @override
  State<TimetableImportReviewScreen> createState() =>
      _TimetableImportReviewScreenState();
}

class _TimetableImportReviewScreenState
    extends State<TimetableImportReviewScreen> {
  late List<ParsedClassSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = widget.initialSlots.map((e) => e.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        title: const Text('Review Parsed Timetable'),
        backgroundColor: NBColors.bg,
      ),
      body: Column(
        children: [
          if (widget.issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: NBCard(
                fillColor: NBColors.orange,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: NBColors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.issues.length} lines could not be parsed. Review before saving.',
                        style: NBText.body,
                      ),
                    ),
                    IconButton(
                      onPressed: _showDebugRawText,
                      icon: const Icon(
                        Icons.bug_report_outlined,
                        color: NBColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _slots.length,
              itemBuilder: (context, index) {
                final slot = _slots[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NBCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.subject, style: NBText.heading3),
                              const SizedBox(height: 4),
                              Text(
                                '${slot.day} • ${slot.startTime24} - ${slot.endTime24} • ${slot.room}',
                                style: NBText.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Confidence ${(slot.confidence * 100).toStringAsFixed(0)}%',
                                style: NBText.label,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editSlot(index),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _slots.removeAt(index)),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: NBButton(
              label: 'Confirm & Save',
              fullWidth: true,
              icon: Icons.check_rounded,
              onTap: _slots.isEmpty
                  ? null
                  : () => Navigator.pop(context, _slots),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSlot(int index) async {
    final original = _slots[index];
    final dayCtrl = TextEditingController(text: original.day);
    final startCtrl = TextEditingController(text: original.startTime24);
    final endCtrl = TextEditingController(text: original.endTime24);
    final subjectCtrl = TextEditingController(text: original.subject);
    final roomCtrl = TextEditingController(text: original.room);
    final durationCtrl = TextEditingController(
      text: original.durationMinutes.toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NBColors.bg,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(dayCtrl, 'Day (Monday-Friday)'),
              const SizedBox(height: 10),
              _field(startCtrl, 'Start (HH:mm)'),
              const SizedBox(height: 10),
              _field(endCtrl, 'End (HH:mm)'),
              const SizedBox(height: 10),
              _field(subjectCtrl, 'Subject'),
              const SizedBox(height: 10),
              _field(roomCtrl, 'Room'),
              const SizedBox(height: 10),
              _field(durationCtrl, 'Duration minutes', isNumber: true),
              const SizedBox(height: 12),
              NBButton(
                label: 'Update Slot',
                fullWidth: true,
                onTap: () {
                  final duration = int.tryParse(durationCtrl.text.trim());
                  if (duration == null || duration <= 0) return;
                  setState(() {
                    _slots[index] = original.copyWith(
                      day: dayCtrl.text.trim(),
                      startTime24: startCtrl.text.trim(),
                      endTime24: endCtrl.text.trim(),
                      subject: subjectCtrl.text.trim(),
                      room: roomCtrl.text.trim(),
                      durationMinutes: duration,
                      confidence: 1,
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(hintText: hint),
    );
  }

  void _showDebugRawText() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NBColors.bg,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              widget.rawText.isEmpty
                  ? 'No extracted raw text available.'
                  : widget.rawText,
              style: NBText.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
