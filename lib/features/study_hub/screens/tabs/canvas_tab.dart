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
  Timer? _docTimer;
  Timer? _codeTimer;
  bool _saved = true;
  static const _modes = ['DOCS', 'CODE', 'WHITEBOARD'];

  // Whiteboard state
  List<Offset?> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _modeTabs = TabController(length: 3, vsync: this);
    _docCtrl.text = widget.svc.docContent;
    _codeCtrl.text = widget.svc.codeContent;

    // Listen for remote updates
    widget.svc.addListener(_onRemoteUpdate);
  }

  @override
  void dispose() {
    _modeTabs.dispose();
    _docCtrl.dispose();
    _codeCtrl.dispose();
    _docTimer?.cancel();
    _codeTimer?.cancel();
    widget.svc.removeListener(_onRemoteUpdate);
    super.dispose();
  }

  void _onRemoteUpdate() {
    // DOCS sync
    if (_docCtrl.text != widget.svc.docContent) {
      final pos = _docCtrl.selection;
      _docCtrl.text = widget.svc.docContent;
      try { _docCtrl.selection = pos; } catch (_) {}
    }
    // CODE sync
    if (_codeCtrl.text != widget.svc.codeContent) {
      final pos = _codeCtrl.selection;
      _codeCtrl.text = widget.svc.codeContent;
      try { _codeCtrl.selection = pos; } catch (_) {}
    }
    setState(() {});
  }

  void _onDocChanged(String text) {
    _saved = false;
    _docTimer?.cancel();
    _docTimer = Timer(const Duration(milliseconds: 800), () {
      widget.svc.updateDoc(text);
      setState(() => _saved = true);
    });
    setState(() {});
  }

  void _onCodeChanged(String text) {
    _saved = false;
    _codeTimer?.cancel();
    _codeTimer = Timer(const Duration(milliseconds: 800), () {
      widget.svc.updateCode(text);
      setState(() => _saved = true);
    });
    setState(() {});
  }

  void _pinNote() {
    final mode = _modes[_modeTabs.index];
    final content = mode == 'DOCS' ? _docCtrl.text.trim() : _codeCtrl.text.trim();
    if (content.isEmpty) return;
    widget.svc.pinItem(
      itemType: mode == 'DOCS' ? 'note' : 'code',
      content: content.length > 100 ? '${content.substring(0, 100)}…' : content,
      label: mode == 'DOCS' ? '📝 Doc note' : '💻 Code snippet',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mode == 'DOCS' ? 'Note' : 'Code'} pinned to chat!')),
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
            children: List.generate(3, (i) {
              final isActive = _modeTabs.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () { _modeTabs.animateTo(i); setState(() {}); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: isActive ? NBColors.blue : Colors.transparent,
                      border: Border(
                        right: i < 2
                            ? const BorderSide(color: NBColors.black, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: Text(_modes[i], style: NBText.label.copyWith(fontSize: 10)),
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
                label: _saved ? '✓ Synced' : '● Editing',
                fillColor: _saved ? NBColors.green : NBColors.orange,
              ),
              const Spacer(),
              if (_modeTabs.index < 2)
                _ToolBtn(icon: Icons.push_pin_outlined, label: 'Pin', onTap: _pinNote),
              const SizedBox(width: 8),
              _ToolBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Clear',
                onTap: () {
                  if (_modeTabs.index == 0) { _docCtrl.clear(); _onDocChanged(''); }
                  if (_modeTabs.index == 1) { _codeCtrl.clear(); _onCodeChanged(''); }
                  if (_modeTabs.index == 2) { 
                    widget.svc.sketches.clear(); // Local clear
                    widget.svc.sendSketch({'action': 'clear'}); 
                  }
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
              _buildTextEditor(_docCtrl, _onDocChanged, 'Start writing shared notes…', null),

              // CODE PASTEBOARD
              _buildTextEditor(_codeCtrl, _onCodeChanged, '// Paste or write code here', NBColors.black),

              // WHITEBOARD
              _buildWhiteboard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextEditor(TextEditingController ctrl, Function(String) onChanged, String hint, Color? bg) {
    final isCode = bg != null;
    return Container(
      color: bg ?? NBColors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        maxLines: null,
        expands: true,
        style: isCode 
          ? NBText.body.copyWith(fontFamily: 'RobotoMono', color: NBColors.green, fontSize: 13, height: 1.6)
          : NBText.body.copyWith(height: 1.6),
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isCode ? const Color(0xFF555555) : const Color(0xFF888888),
            fontFamily: isCode ? 'RobotoMono' : null,
            fontSize: isCode ? 13 : 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildWhiteboard() {
    return GestureDetector(
      onPanStart: (details) {
        setState(() => _currentPoints = [details.localPosition]);
      },
      onPanUpdate: (details) {
        setState(() => _currentPoints.add(details.localPosition));
      },
      onPanEnd: (_) {
        if (_currentPoints.isNotEmpty) {
          final data = {
            'action': 'sketch',
            'points': _currentPoints.map((p) => p == null ? null : {'x': p.dx, 'y': p.dy}).toList(),
          };
          widget.svc.sendSketch(data);
          _currentPoints = [];
        }
      },
      child: Container(
        color: NBColors.bg,
        child: CustomPaint(
          painter: WhiteboardPainter(
            sketches: widget.svc.sketches,
            currentPoints: _currentPoints,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<Map<String, dynamic>> sketches;
  final List<Offset?> currentPoints;

  WhiteboardPainter({required this.sketches, required this.currentPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NBColors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw persistent sketches
    for (final sk in sketches) {
      if (sk['data']?['action'] == 'sketch') {
        final pts = sk['data']['points'] as List;
        for (int i = 0; i < pts.length - 1; i++) {
          if (pts[i] != null && pts[i + 1] != null) {
            canvas.drawLine(
              Offset(pts[i]['x'].toDouble(), pts[i]['y'].toDouble()),
              Offset(pts[i+1]['x'].toDouble(), pts[i+1]['y'].toDouble()),
              paint,
            );
          }
        }
      }
    }

    // Draw current active stroke
    for (int i = 0; i < currentPoints.length - 1; i++) {
      if (currentPoints[i] != null && currentPoints[i + 1] != null) {
        canvas.drawLine(currentPoints[i]!, currentPoints[i + 1]!, paint..color = NBColors.primary);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
