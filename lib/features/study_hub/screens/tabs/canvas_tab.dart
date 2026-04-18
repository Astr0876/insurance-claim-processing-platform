// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/tabs/canvas_tab.dart
//  Shared document / canvas tab with live sync
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/neubrut_tokens.dart';
import '../../../../core/widgets/nb_card.dart';
import '../../../../core/widgets/nb_button.dart';
import '../../../../core/widgets/nb_badge.dart';
import '../../services/hub_service.dart';

class CanvasTab extends StatefulWidget {
  final HubService svc;
  const CanvasTab({super.key, required this.svc});

  @override
  State<CanvasTab> createState() => _CanvasTabState();
}

class _CanvasTabState extends State<CanvasTab>
    with SingleTickerProviderStateMixin {
  late TabController _modeTabs;
  final _docCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  Timer? _autoSaveTimer;
  bool _saved = true;
  static const _modes = ['DOCS', 'CODE'];

  @override
  void initState() {
    super.initState();
    _modeTabs = TabController(length: 2, vsync: this);
    _docCtrl.text = widget.svc.docContent;

    // Listen for remote doc updates
    widget.svc.addListener(_onRemoteDocUpdate);
  }

  @override
  void dispose() {
    _modeTabs.dispose();
    _docCtrl.dispose();
    _codeCtrl.dispose();
    _autoSaveTimer?.cancel();
    widget.svc.removeListener(_onRemoteDocUpdate);
    super.dispose();
  }

  void _onRemoteDocUpdate() {
    // Only update if content differs (avoid cursor jumps from own edits)
    if (_docCtrl.text != widget.svc.docContent) {
      final pos = _docCtrl.selection;
      _docCtrl.text = widget.svc.docContent;
      try { _docCtrl.selection = pos; } catch (_) {}
    }
  }

  void _onDocChanged(String text) {
    _saved = false;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      widget.svc.updateDoc(text);
      setState(() => _saved = true);
    });
    setState(() {});
  }

  void _pinNote() {
    final content = _docCtrl.text.trim();
    if (content.isEmpty) return;
    widget.svc.pinItem(
      itemType: 'note',
      content: content.length > 100 ? '${content.substring(0, 100)}…' : content,
      label: '📝 Doc note',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note pinned to chat!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Mode selector ─────────────────────────────────────────
        Container(
          height: 42,
          decoration: const BoxDecoration(
            color: NBColors.bg,
            border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
          ),
          child: Row(
            children: List.generate(2, (i) {
              final isActive = _modeTabs.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () { _modeTabs.animateTo(i); setState(() {}); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: isActive ? NBColors.blue : Colors.transparent,
                      border: Border(
                        right: i == 0
                            ? const BorderSide(color: NBColors.black, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: Text(_modes[i], style: NBText.label.copyWith(fontSize: 11)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Toolbar ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: NBColors.white,
            border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
          ),
          child: Row(
            children: [
              NBBadge(
                label: _saved ? '✓ Saved' : '● Editing',
                fillColor: _saved ? NBColors.green : NBColors.orange,
              ),
              const Spacer(),
              _ToolBtn(icon: Icons.push_pin_outlined, label: 'Pin Note', onTap: _pinNote),
              const SizedBox(width: 8),
              _ToolBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Clear',
                onTap: () {
                  _docCtrl.clear();
                  _onDocChanged('');
                },
              ),
            ],
          ),
        ),

        // ── Editor ────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _modeTabs,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // DOCS
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _docCtrl,
                  onChanged: _onDocChanged,
                  maxLines: null,
                  expands: true,
                  style: NBText.body.copyWith(height: 1.6),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Start writing shared notes here…\n\nTip: Use # for headings, - for lists',
                    hintStyle: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // CODE PASTEBOARD
              Container(
                padding: const EdgeInsets.all(16),
                color: NBColors.black,
                child: TextField(
                  controller: _codeCtrl,
                  maxLines: null,
                  expands: true,
                  style: NBText.body.copyWith(
                    fontFamily: 'RobotoMono',
                    color: NBColors.green,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '// Paste or write code here\n// Shared with everyone in real-time',
                    hintStyle: TextStyle(
                      fontFamily: 'RobotoMono',
                      color: Color(0xFF555555),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: NBShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: NBColors.black),
            const SizedBox(width: 4),
            Text(label, style: NBText.label.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
