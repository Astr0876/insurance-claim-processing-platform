import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/parser_service.dart';
import '../services/analytics_service.dart';
import '../services/suggestion_engine.dart';

class ExpenseController extends ChangeNotifier {
  final List<dynamic> _chatMessages = [];
  final List<TransactionModel> _transactions = [];

  List<dynamic> get chatMessages => List.unmodifiable(_chatMessages);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  AnalyticsService get analytics => AnalyticsService(_transactions);
  List<SuggestionModel> get suggestions => SuggestionEngine.generateSuggestions(_transactions);

  void handleInput(String input) {
    if (input.trim().isEmpty) return;
    
    // Add user message
    _chatMessages.add({'type': 'user', 'text': input});
    notifyListeners();

    // Parse and add transaction
    final newTransaction = ParserService.parseMessage(input);
    _transactions.add(newTransaction);
    
    // Add system confirmation
    _chatMessages.add({'type': 'system', 'transaction': newTransaction});
    notifyListeners();
  }

  void clearAll() {
    _chatMessages.clear();
    _transactions.clear();
    notifyListeners();
  }
}
