// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/tabs/chat_tab.dart
//  Real-time chat tab — Neubrutalism card messages
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/neubrut_tokens.dart';
import '../../../../core/widgets/nb_card.dart';
import '../../../../core/widgets/nb_badge.dart';
import '../../services/hub_service.dart';
import '../../models/hub_models.dart';

class ChatTab extends StatefulWidget {
  final HubService svc;
  const ChatTab({super.key, required this.svc});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    widget.svc.addListener(_onMessagesChanged);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    widget.svc.removeListener(_onMessagesChanged);
    super.dispose();
  }

  void _onMessagesChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String v) {
    if (!_isTyping) {
      _isTyping = true;
      widget.svc.sendTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      widget.svc.sendTyping(false);
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    widget.svc.sendMessage(text);
    _msgCtrl.clear();
    _isTyping = false;
    widget.svc.sendTyping(false);
    _typingTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;

    return Column(
      children: [
        // ── Pinned section ─────────────────────────────────────────
        if (svc.pinnedItems.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: NBColors.primary,
              border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text('PINNED', style: NBText.label.copyWith(letterSpacing: 2, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  svc.pinnedItems.first.content,
                  style: NBText.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

        // ── Messages list ──────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: svc.messages.length + (svc.typingUsers.isNotEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == svc.messages.length) return _TypingIndicator(names: svc.typingUsers.keys.toList());
              return _MessageCard(
                msg: svc.messages[i],
                myId: svc.userId,
                onPin: (msg) => svc.pinItem(
                  itemType: 'message',
                  content: msg.content,
                  label: '📌 From ${msg.senderName}',
                ),
              );
            },
          ),
        ),

        // ── Input bar ──────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
          decoration: const BoxDecoration(
            color: NBColors.white,
            border: Border(top: BorderSide(color: NBColors.black, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: NBColors.bg,
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: NBText.body,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(onTap: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Message card ──────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final HubMessage msg;
  final String myId;
  final Function(HubMessage) onPin;

  const _MessageCard({required this.msg, required this.myId, required this.onPin});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: NBColors.black,
              borderRadius: NBRadius.softAll,
            ),
            child: Text(msg.content, style: NBText.label.copyWith(color: NBColors.white, fontSize: 10)),
          ),
        ),
      );
    }

    final isMe = msg.senderId == myId;
    final time = _formatTime(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: NBColors.blue,
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
              ),
              child: Center(
                child: Text(
                  msg.senderName.substring(0, 1).toUpperCase(),
                  style: NBText.label.copyWith(fontSize: 12),
                ),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => onPin(msg),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? NBColors.primary : NBColors.white,
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.small,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        msg.senderName.toUpperCase(),
                        style: NBText.label.copyWith(fontSize: 9, letterSpacing: 1.5),
                      ),
                    if (!isMe) const SizedBox(height: 4),
                    Text(msg.content, style: NBText.body.copyWith(height: 1.4)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time, style: NBText.monoSmall.copyWith(fontSize: 10, color: const Color(0xFF666666))),
                        if (isMe && msg.readBy.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all_rounded, size: 12, color: NBColors.green),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}

// ── Typing indicator ──────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final List<String> names;
  const _TypingIndicator({required this.names});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: NBColors.white,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
              boxShadow: NBShadows.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${names.first} is typing',
                  style: NBText.bodySmall.copyWith(color: const Color(0xFF666666), fontStyle: FontStyle.italic),
                ),
                const SizedBox(width: 8),
                ...List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? NBColors.black : NBColors.primary,
                    border: Border.all(color: NBColors.black, width: 1),
                    borderRadius: NBRadius.softAll,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() { _pressed = false; widget.onTap(); }),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NBColors.primary,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: _pressed ? NBShadows.pressed : NBShadows.small,
        ),
        child: const Icon(Icons.send_rounded, color: NBColors.black, size: 20),
      ),
    );
  }
}
