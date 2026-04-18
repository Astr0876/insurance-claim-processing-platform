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

  factory TransactionModel.fromSupabase(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: double.tryParse(map['amount'].toString()) ?? 0.0,
      category: map['category'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.spent,
      ),
      date: DateTime.parse(map['date']),
      rawMessage: map['raw_message'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      peopleCount: map['people_count'] ?? 1,
    );
  }

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category,
      'type': type.toString().split('.').last,
      'tags': tags,
      'people_count': peopleCount,
      'raw_message': rawMessage,
      'date': date.toIso8601String(),
    };
  }

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
