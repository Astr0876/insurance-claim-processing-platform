import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/assistant_service.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';

class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller      = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "👋 Hi! I'm LUMINA's Offline Semantic Assistant.\n\n"
            "I can answer questions from your study materials. Demo notes are pre-loaded.\n\n"
            "Try the new **Lumina RAG** mode for smarter, synthesized answers using your local second brain!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final state = Provider.of<AppState>(context, listen: false);
    final assistant = state.assistant;

    if (assistant.mode == AssistantMode.standard) {
      await Future.delayed(const Duration(milliseconds: 600));
      final answer = assistant.getAnswer(text);
      setState(() {
        _messages.add(ChatMessage(text: answer, isUser: false));
        _isTyping = false;
      });
    } else {
      // RAG Streaming mode
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: "...", isUser: false, isStreaming: true));
      });
      
      final currentMessage = _messages.last;
      await for (final token in assistant.getAnswerStream(text)) {
        setState(() {
          currentMessage.text = token;
        });
        _scrollToBottom();
      }
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final assistant = state.assistant;

    return Scaffold(
      backgroundColor: NBColors.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
            decoration: BoxDecoration(
              color: assistant.mode == AssistantMode.luminaRag 
                  ? const Color(0xFFE1BEE7) // Soft Purple for RAG
                  : NBColors.primary,
              border: const Border(
                bottom: BorderSide(color: NBColors.black, width: 2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Bot icon box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NBColors.white,
                        border: Border.all(color: NBColors.black, width: 2),
                        borderRadius: NBRadius.softAll,
                        boxShadow: NBShadows.small,
                      ),
                      child: Icon(
                        assistant.mode == AssistantMode.luminaRag 
                            ? Icons.psychology_rounded
                            : Icons.smart_toy_rounded,
                        color: NBColors.black,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assistant.mode == AssistantMode.luminaRag 
                                ? 'LUMINA RAG'
                                : 'SEMANTIC ASSISTANT',
                            style: NBText.label.copyWith(
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                color: assistant.mode == AssistantMode.luminaRag 
                                    ? Colors.purple
                                    : NBColors.green,
                                margin: const EdgeInsets.only(right: 6),
                              ),
                              Text(
                                assistant.mode == AssistantMode.luminaRag 
                                    ? 'LOCAL BRAIN • OFFLINE'
                                    : 'QUICK SEARCH • OFFLINE',
                                style: NBText.label.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Clear button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _messages.clear();
                          _messages.add(ChatMessage(
                            text: 'Memory wiped. Ask me anything! 🧠',
                            isUser: false,
                          ));
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NBColors.white,
                          border: Border.all(color: NBColors.black, width: 2),
                          borderRadius: NBRadius.softAll,
                          boxShadow: NBShadows.small,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: NBColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Upload button
                    GestureDetector(
                      onTap: () async {
                        final state = Provider.of<AppState>(context, listen: false);
                        try {
                          final result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'txt'],
                          );

                          if (result != null && result.files.single.path != null) {
                            final fileName = result.files.single.name;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Indexing $fileName into Local Brain...'),
                                backgroundColor: Colors.purple,
                              ),
                            );
                            
                            // Simulate reading the file content
                            // In a real app, you'd use a PDF parser like syncfusion_flutter_pdf
                            await Future.delayed(const Duration(seconds: 2));
                            
                            state.assistant.loadDocument("Content from $fileName: This is a deep dive into the subject matter of $fileName. It covers key concepts, definitions, and advanced theories that Lumina can now use to answer your queries offline.");
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$fileName Indexed! ✨'),
                                  backgroundColor: NBColors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error selecting file')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NBColors.white,
                          border: Border.all(color: NBColors.black, width: 2),
                          borderRadius: NBRadius.softAll,
                          boxShadow: NBShadows.small,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: NBColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Mode Switcher ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Standard',
                        icon: Icons.search_rounded,
                        isSelected: assistant.mode == AssistantMode.standard,
                        onTap: () => assistant.setMode(AssistantMode.standard),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeButton(
                        label: 'Lumina RAG',
                        icon: Icons.auto_awesome_rounded,
                        isSelected: assistant.mode == AssistantMode.luminaRag,
                        onTap: () => assistant.setMode(AssistantMode.luminaRag),
                        isSpecial: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Messages list ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // ── Input area ────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: NBColors.white,
              border: Border(
                top: BorderSide(color: NBColors.black, width: 2),
              ),
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
                      controller: _controller,
                      style: NBText.body,
                      decoration: InputDecoration(
                        hintText: assistant.mode == AssistantMode.luminaRag 
                            ? 'Query your local brain...' 
                            : 'Ask about your notes...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SendButton(onSend: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: NBColors.white,
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
                boxShadow: NBShadows.small,
              ),
              child: Icon(
                message.isStreaming ? Icons.psychology_rounded : Icons.smart_toy_rounded,
                color: NBColors.black,
                size: 16,
              ),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? NBColors.primary 
                    : (message.isStreaming ? const Color(0xFFF3E5F5) : NBColors.white),
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
                boxShadow: NBShadows.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: NBText.body.copyWith(height: 1.5),
                  ),
                  if (message.isStreaming && message.text.contains("Thinking"))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: Colors.purple,
                        minHeight: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: NBColors.white,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: NBColors.black, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: NBColors.white,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
              boxShadow: NBShadows.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + i * 150),
                  builder: (context, value, _) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? NBColors.black : NBColors.primary,
                        border: Border.all(color: NBColors.black, width: 1.5),
                        borderRadius: NBRadius.softAll,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSpecial;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isSpecial ? Colors.purple : NBColors.black)
              : NBColors.white,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: isSelected ? NBShadows.pressed : NBShadows.small,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? NBColors.white : NBColors.black,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: NBText.label.copyWith(
                fontSize: 10,
                color: isSelected ? NBColors.white : NBColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback onSend;
  const _SendButton({required this.onSend});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() { _pressed = false; widget.onSend(); }),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(13),
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
