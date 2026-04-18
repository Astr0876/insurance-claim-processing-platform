import '../models/transaction_model.dart';
import 'analytics_service.dart';

class SuggestionEngine {
  static List<SuggestionModel> generateSuggestions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return [];

    final suggestions = <SuggestionModel>[];
    final analytics = AnalyticsService(transactions);
    
    final breakdown = analytics.getCategoryBreakdown();
    final totalSpent = analytics.totalSpent;
    
    if (totalSpent == 0) return suggestions;

    // Detect high percentage spending
    breakdown.forEach((category, amount) {
      double percentage = (amount / totalSpent) * 100;
      
      if (percentage > 40 && category == 'Food') {
        suggestions.add(SuggestionModel(
          message: 'You spent ${percentage.toStringAsFixed(0)}% on food. Reduce by 10% to save ₹${(amount * 0.10).toStringAsFixed(0)}.',
          type: 'warning',
        ));
      } else if (percentage > 30 && category == 'Travel') {
        suggestions.add(SuggestionModel(
          message: 'Travel is taking up ${percentage.toStringAsFixed(0)}% of your expenses. Consider pooling or public transport.',
          type: 'info',
        ));
      } else if (percentage > 50 && category == 'Shopping') {
        suggestions.add(SuggestionModel(
          message: 'Warning: Huge shopping spend (${percentage.toStringAsFixed(0)}%). Consider a cooling-off period before big purchases.',
          type: 'danger',
        ));
      }
    });

    if (suggestions.isEmpty) {
      suggestions.add(SuggestionModel(
        message: 'Your spending looks balanced across categories. Keep it up!',
        type: 'success',
      ));
    }

    return suggestions;
  }
}
