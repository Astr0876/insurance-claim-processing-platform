import 'package:flutter/material.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_card.dart';
import '../../../core/widgets/nb_button.dart';
import '../controllers/expense_controller.dart';

class ExpenseWrappedScreen extends StatefulWidget {
  final ExpenseController controller;

  const ExpenseWrappedScreen({super.key, required this.controller});

  @override
  State<ExpenseWrappedScreen> createState() => _ExpenseWrappedScreenState();
}

class _ExpenseWrappedScreenState extends State<ExpenseWrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = widget.controller.analytics;
    final breakdown = analytics.getCategoryBreakdown();
    final topCategory = analytics.getHighestSpendingCategory();
    final total = analytics.totalSpent;

    final List<Widget> pages = [
      _buildIntroPage(total),
      _buildTopCategoryPage(topCategory, breakdown[topCategory] ?? 0),
      _buildBreakdownPage(breakdown),
      _buildVibePage(topCategory, total),
    ];

    return Scaffold(
      backgroundColor: NBColors.bg,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: pages,
          ),
          
          // Progress indicators
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(pages.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentPage >= index 
                          ? NBColors.black 
                          : NBColors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NBColors.white,
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.small,
                ),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(double total) {
    return Container(
      color: NBColors.primary,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          Text(
            'EXPENSE\nWRAPPED',
            style: NBText.heading1.copyWith(fontSize: 48, height: 0.9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          NBCard(
            fillColor: NBColors.white,
            child: Column(
              children: [
                const Text('YOU SPENT A TOTAL OF', style: NBText.label),
                const SizedBox(height: 10),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: NBText.heading1.copyWith(fontSize: 56),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text('SWIPE TO SEE YOUR VIBE', style: NBText.label),
          const Icon(Icons.keyboard_arrow_right, size: 30),
        ],
      ),
    );
  }

  Widget _buildTopCategoryPage(String category, double amount) {
    return Container(
      color: NBColors.pink,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          const Text('YOUR NUMBER ONE IS', style: NBText.label),
          const SizedBox(height: 10),
          Text(
            category.toUpperCase(),
            style: NBText.heading1.copyWith(fontSize: 48, height: 0.9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          NBCard(
            fillColor: NBColors.white,
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: NBText.heading1.copyWith(fontSize: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'That\'s a lot of ${category.toLowerCase()}!',
            style: NBText.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownPage(Map<String, double> breakdown) {
    return Container(
      color: NBColors.blue,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE\nBREAKDOWN',
            style: NBText.heading1.copyWith(fontSize: 40, height: 0.9),
          ),
          const SizedBox(height: 30),
          ...breakdown.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NBCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                fillColor: NBColors.white,
                child: Row(
                  children: [
                    Text(e.key.toUpperCase(), style: NBText.label),
                    const Spacer(),
                    Text('₹${e.value.toStringAsFixed(0)}', style: NBText.monoSmall),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVibePage(String topCategory, double total) {
    String vibeTitle = "THE SAVER";
    String vibeDesc = "Your wallet is breathing easy.";
    Color vibeColor = NBColors.green;
    String emoji = "💰";

    if (total > 5000) {
      vibeTitle = "THE BIG SPENDER";
      vibeDesc = "Living life to the fullest, one transaction at a time.";
      vibeColor = NBColors.orange;
      emoji = "💸";
    }

    if (topCategory == 'Food') {
      vibeTitle = "THE FOODIE";
      vibeDesc = "If it tastes good, it's worth it.";
      emoji = "🍕";
    } else if (topCategory == 'Travel') {
      vibeTitle = "THE EXPLORER";
      vibeDesc = "Always on the move.";
      emoji = "🚗";
    }

    return Container(
      color: vibeColor,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          const Text('YOUR SPENDING VIBE IS', style: NBText.label),
          const SizedBox(height: 10),
          Text(
            vibeTitle,
            style: NBText.heading1.copyWith(fontSize: 44, height: 0.9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          NBCard(
            fillColor: NBColors.white,
            child: Text(
              vibeDesc,
              style: NBText.body.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          NBButton(
            label: 'DONE',
            onTap: () => Navigator.pop(context),
            fillColor: NBColors.white,
          ),
        ],
      ),
    );
  }
}
