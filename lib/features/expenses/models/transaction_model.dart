enum TransactionType { spent, received, split }

class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final TransactionType type;
  final List<String> tags;
  final int peopleCount;
  final DateTime date;
  final String rawMessage;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.rawMessage,
    this.tags = const [],
    this.peopleCount = 1,
  });

  double get effectiveAmount {
    if (type == TransactionType.split && peopleCount > 0) {
      return amount / peopleCount;
    }
    return amount;
  }
}

class SuggestionModel {
  final String message;
  final String type; // e.g., 'warning', 'info', 'success'

  SuggestionModel({required this.message, required this.type});
}
