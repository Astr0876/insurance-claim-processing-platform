import 'package:flutter/material.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_card.dart';
import '../models/transaction_model.dart';
import 'category_badge.dart';

class ExpenseChatBubble extends StatelessWidget {
  final dynamic message; // Expecting Map representing user or system, or TransactionModel

  const ExpenseChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message['type'] == 'user';
    
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: NBSpacing.md, left: 40),
          decoration: BoxDecoration(
            color: NBColors.white,
            border: Border.all(color: NBColors.black, width: 2),
            borderRadius: BorderRadius.circular(NBRadius.max),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            message['text'],
            style: NBText.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    // System parsed message
    TransactionModel tx = message['transaction'];
    bool isReceived = tx.type == TransactionType.received;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: NBSpacing.md, right: 40),
        child: NBCard(
          fillColor: isReceived ? NBColors.green : NBColors.pink,
          padding: const EdgeInsets.all(NBSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 20,
                  ),
                  const SizedBox(width: NBSpacing.sm),
                  Text(
                    isReceived ? 'LOGGED INCOME' : 'LOGGED EXPENSE',
                    style: NBText.label,
                  ),
                ],
              ),
              const SizedBox(height: NBSpacing.sm),
              Text(
                '${tx.type == TransactionType.received ? "+" : "-"}₹${tx.effectiveAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (tx.peopleCount > 1) ...[
                const SizedBox(height: NBSpacing.xs),
                Text(
                  '(Total: ₹${tx.amount.toStringAsFixed(2)} split among ${tx.peopleCount})',
                  style: NBText.bodySmall,
                ),
              ],
              const SizedBox(height: NBSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryBadge(category: tx.category),
                  if (tx.tags.isNotEmpty) ...[
                     const SizedBox(width: NBSpacing.sm),
                     Text(
                       tx.tags.map((t) => '#$t').join(' '),
                       style: NBText.bodySmall.copyWith(fontWeight: FontWeight.bold),
                     )
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
