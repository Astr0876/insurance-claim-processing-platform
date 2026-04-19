import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_input.dart';
import '../../../core/widgets/nb_button.dart';
import '../../../core/providers/app_state.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expense_chat_bubble.dart';
import '../widgets/expense_summary_card.dart';
import 'expense_wrapped_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend(ExpenseController controller) {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    
    controller.handleInput(text);
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final controller = appState.expenses;

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.payments_rounded, size: 20),
            const SizedBox(width: 8),
            Text('EXPENSES', style: NBText.heading3),
          ],
        ),
      ),
      body: Column(
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
              if (controller.transactions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseWrappedScreen(controller: controller),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NBColors.primary,
                      border: Border.all(color: NBColors.black, width: 1.5),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text('WRAPPED ✨', style: NBText.label.copyWith(fontSize: 9)),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  controller.clearAll();
                },
                child: Text('CLEAR ALL', style: NBText.label.copyWith(fontSize: 10, color: NBColors.danger)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(NBSpacing.md),
            children: [
              // Render Summary at the top if there are transations
              if (controller.transactions.isNotEmpty) ...[
                ExpenseSummaryCard(controller: controller),
                const SizedBox(height: NBSpacing.xl),
              ],
              // Render chat messages
              ...controller.chatMessages.map(
                (msg) => ExpenseChatBubble(message: msg),
              ),
            ],
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
                  onSubmitted: (_) => _handleSend(controller),
                ),
              ),
              const SizedBox(width: NBSpacing.sm),
              NBButton(
                label: 'SEND',
                onTap: () => _handleSend(controller),
                icon: Icons.send,
                fillColor: NBColors.primary,
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
