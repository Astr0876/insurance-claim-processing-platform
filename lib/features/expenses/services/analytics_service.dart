import '../models/transaction_model.dart';

class AnalyticsService {
  final List<TransactionModel> transactions;

  AnalyticsService(this.transactions);

  double get totalSpent {
    return transactions
        .where((t) => t.type == TransactionType.spent || t.type == TransactionType.split)
        .fold(0.0, (sum, t) => sum + t.effectiveAmount);
  }

  double get totalReceived {
    return transactions
        .where((t) => t.type == TransactionType.received)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryBreakdown() {
    Map<String, double> breakdown = {};
    for (var t in transactions) {
      if (t.type == TransactionType.spent || t.type == TransactionType.split) {
        breakdown[t.category] = (breakdown[t.category] ?? 0) + t.effectiveAmount;
      }
    }
    return breakdown;
  }

  String getHighestSpendingCategory() {
    var breakdown = getCategoryBreakdown();
    if (breakdown.isEmpty) return 'None';
    
    String topCategory = breakdown.keys.first;
    double maxAmount = breakdown[topCategory]!;
    
    breakdown.forEach((key, value) {
      if (value > maxAmount) {
        maxAmount = value;
        topCategory = key;
      }
    });
    
    return topCategory;
  }
}
