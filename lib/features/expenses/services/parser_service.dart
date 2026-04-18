import '../models/transaction_model.dart';

class ParserService {
  static TransactionModel parseMessage(String input) {
    String lower = input.toLowerCase();
    
    // Default values
    TransactionType type = TransactionType.spent;
    double amount = 0;
    String category = 'Others';
    List<String> tags = [];
    int peopleCount = 1;

    // 1. Detect Action
    if (lower.contains('received') || lower.contains('got') || lower.contains('credited') || lower.contains('salary')) {
      type = TransactionType.received;
    } else if (lower.contains('split') || lower.contains('divided')) {
      type = TransactionType.split;
      
      // Extract people count: e.g., "with 4 friends", "split 800 by 4"
      RegExp peopleRegex = RegExp(r'(?:with |among |by )?(\d+)(?: friends| people| guys)?');
      var peopleMatch = peopleRegex.firstMatch(lower);
      if (peopleMatch != null && peopleMatch.group(1) != null) {
        peopleCount = int.tryParse(peopleMatch.group(1)!) ?? 1;
        // If they say "with 4 friends", meaning user + 4 = 5 total
        if (lower.contains('with')) {
          peopleCount += 1;
        }
      }
    } else if (lower.contains('spent') || lower.contains('paid') || lower.contains('bought')) {
      type = TransactionType.spent;
    }

    // 2. Extract Amount
    RegExp amountRegex = RegExp(r'(?:rs|inr|₹)?\s?(\d+(?:\.\d{1,2})?)');
    var amountMatch = amountRegex.firstMatch(lower);
    if (amountMatch != null && amountMatch.group(1) != null) {
      amount = double.tryParse(amountMatch.group(1)!) ?? 0;
    }

    // 3. Extract Tags
    RegExp tagRegex = RegExp(r'#(\w+)');
    var tagMatches = tagRegex.allMatches(lower);
    tags = tagMatches.map((m) => m.group(1)!).toList();

    // 4. Infer Category
    Map<String, List<String>> categoryKeywords = {
      'Food': ['food', 'lunch', 'dinner', 'breakfast', 'restaurant', 'cafe', 'swiggy', 'zomato', 'snack', 'grocery', 'meal'],
      'Travel': ['uber', 'ola', 'cab', 'bus', 'train', 'flight', 'travel', 'ticket', 'petrol', 'gas', 'rickshaw', 'auto'],
      'Rent': ['rent', 'lease', 'deposit', 'room', 'hostel'],
      'Shopping': ['amazon', 'flipkart', 'clothes', 'shoes', 'shopping', 'mall', 'myntra'],
      'Utilities': ['electricity', 'water', 'bill', 'recharge', 'wifi', 'internet', 'mobile'],
      'Entertainment': ['movie', 'netflix', 'spotify', 'concert', 'game', 'club', 'party'],
    };

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (lower.contains(keyword) || tags.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != 'Others') break;
    }

    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      type: type,
      date: DateTime.now(),
      rawMessage: input,
      tags: tags,
      peopleCount: peopleCount,
    );
  }
}
