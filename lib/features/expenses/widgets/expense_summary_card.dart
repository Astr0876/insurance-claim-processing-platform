import 'package:flutter/material.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_card.dart';
import '../controllers/expense_controller.dart';
import 'category_badge.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NBCard(
          fillColor: NBColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WEEKLY SUMMARY',
                style: NBText.heading3.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: NBSpacing.md),
              Text(
                'TOTAL SPENT',
                style: NBText.label,
              ),
              Text(
                '₹${controller.analytics.totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: NBColors.black,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: NBSpacing.md),
              Text(
                'TOP CATEGORY',
                style: NBText.label,
              ),
              const SizedBox(height: NBSpacing.xs),
              CategoryBadge(category: controller.analytics.getHighestSpendingCategory()),
            ],
          ),
        ),
        if (controller.suggestions.isNotEmpty) ...[
          const SizedBox(height: NBSpacing.md),
          NBCard(
            fillColor: _getSuggestionColor(controller.suggestions.first.type),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 24),
                    const SizedBox(width: NBSpacing.sm),
                    Text('INSIGHT', style: NBText.heading3.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: NBSpacing.sm),
                Text(
                  controller.suggestions.first.message,
                  style: NBText.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ]
      ],
    );
  }

  Color _getSuggestionColor(String type) {
    if (type == 'danger') return NBColors.danger;
    if (type == 'warning') return NBColors.orange;
    if (type == 'success') return NBColors.green;
    return NBColors.blue;
  }
}
