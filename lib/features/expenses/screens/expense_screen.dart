import 'package:flutter/material.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_input.dart';
import '../../../core/widgets/nb_button.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expense_chat_bubble.dart';
import '../widgets/expense_summary_card.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseController _controller = ExpenseController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    
    _controller.handleInput(text);
    _textController.clear();
    
    // Scroll down to the bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200, // accommodate cards
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Info Bar ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: NBColors.white,
            border: Border(
              bottom: BorderSide(color: NBColors.black, width: 2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 16),
              const SizedBox(width: 8),
              Text(
                'STUDENT EXPENSE TRACKER',
                style: NBText.label.copyWith(fontSize: 10),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.clearAll();
                  });
                },
                child: Text('CLEAR ALL', style: NBText.label.copyWith(fontSize: 10, color: NBColors.danger)),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(NBSpacing.md),
                children: [
                  // Render Summary at the top if there are transations
                  if (_controller.transactions.isNotEmpty) ...[
                    ExpenseSummaryCard(controller: _controller),
                    const SizedBox(height: NBSpacing.xl),
                  ],
                  // Render chat messages
                  ..._controller.chatMessages.map(
                    (msg) => ExpenseChatBubble(message: msg),
                  ),
                ],
              );
            },
          ),
        ),
        // Input Bar
        Container(
          decoration: const BoxDecoration(
            color: NBColors.white,
            border: Border(top: BorderSide(color: NBColors.black, width: 2)),
          ),
          padding: const EdgeInsets.all(NBSpacing.md).copyWith(
              bottom: NBSpacing.md + MediaQuery.of(context).padding.bottom),
          child: Row(
            children: [
              Expanded(
                child: NBInput(
                  controller: _textController,
                  hintText: 'E.g., Spent 200 on food #swiggy',
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: NBSpacing.sm),
              NBButton(
                label: 'SEND',
                onTap: _handleSend,
                icon: Icons.send,
                fillColor: NBColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
