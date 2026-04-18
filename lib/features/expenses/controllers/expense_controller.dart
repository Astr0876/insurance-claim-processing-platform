import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../services/parser_service.dart';
import '../services/analytics_service.dart';
import '../services/suggestion_engine.dart';

class ExpenseController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<dynamic> _chatMessages = [];
  List<TransactionModel> _transactions = [];

  List<dynamic> get chatMessages => List.unmodifiable(_chatMessages);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  AnalyticsService get analytics => AnalyticsService(_transactions);
  List<SuggestionModel> get suggestions => SuggestionEngine.generateSuggestions(_transactions);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ExpenseController() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true);

      _transactions = (response as List).map((t) => TransactionModel.fromSupabase(t)).toList();
      _chatMessages.clear();
      for (var t in _transactions) {
        _chatMessages.add({'type': 'user', 'text': t.rawMessage});
        _chatMessages.add({'type': 'system', 'transaction': t});
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleInput(String input) async {
    if (input.trim().isEmpty) return;
    
    // Add user message
    _chatMessages.add({'type': 'user', 'text': input});
    notifyListeners();

    // Parse transaction
    final newTransaction = ParserService.parseMessage(input);
    
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('transactions')
            .insert(newTransaction.toSupabase(user.id))
            .select()
            .single();
        
        final savedTransaction = TransactionModel.fromSupabase(response);
        _transactions.add(savedTransaction);
        
        // Add system confirmation
        _chatMessages.add({'type': 'system', 'transaction': savedTransaction});
        notifyListeners();
      } catch (e) {
        debugPrint('Error saving transaction: $e');
      }
    } else {
      // Offline / No-auth fallback
      _transactions.add(newTransaction);
      _chatMessages.add({'type': 'system', 'transaction': newTransaction});
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('transactions').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Error clearing transactions: $e');
      }
    }
    _chatMessages.clear();
    _transactions.clear();
    notifyListeners();
  }
}
