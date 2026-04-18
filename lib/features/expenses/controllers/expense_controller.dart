import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction_model.dart';
import '../services/parser_service.dart';
import '../services/analytics_service.dart';
import '../services/suggestion_engine.dart';
import '../../../services/local_db_service.dart';

class ExpenseController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabaseService();
  final List<dynamic> _chatMessages = [];
  List<TransactionModel> _transactions = [];
  StreamSubscription? _connectivitySubscription;

  List<dynamic> get chatMessages => List.unmodifiable(_chatMessages);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  AnalyticsService get analytics => AnalyticsService(_transactions);
  List<SuggestionModel> get suggestions => SuggestionEngine.generateSuggestions(_transactions);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ExpenseController() {
    _init();
  }

  Future<void> _init() async {
    await fetchTransactions();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // ignore: iterable_contains_unrelated_type
      if (results.any((result) => result != ConnectivityResult.none)) {
        syncUnsyncedTransactions();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load from local DB first for immediate UI update
      _transactions = await _localDb.getAllTransactions(user.id);
      _updateChatMessages();
      notifyListeners();

      // 2. Fetch from Supabase
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true);

      final remoteTransactions = (response as List).map((t) => TransactionModel.fromSupabase(t)).toList();
      
      // 3. Update local DB with remote data
      for (var t in remoteTransactions) {
        await _localDb.insertTransaction(t, user.id, isSynced: true);
      }

      // 4. Reload from local DB to get merged state
      _transactions = await _localDb.getAllTransactions(user.id);
      _updateChatMessages();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateChatMessages() {
    _chatMessages.clear();
    for (var t in _transactions) {
      _chatMessages.add({'type': 'user', 'text': t.rawMessage});
      _chatMessages.add({'type': 'system', 'transaction': t});
    }
  }

  Future<void> handleInput(String input) async {
    if (input.trim().isEmpty) return;
    
    // Add user message to UI immediately
    _chatMessages.add({'type': 'user', 'text': input});
    notifyListeners();

    // Parse transaction
    final newTransaction = ParserService.parseMessage(input);
    
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // 1. Save to local DB first (unsynced)
      await _localDb.insertTransaction(newTransaction, user.id, isSynced: false);
      _transactions.add(newTransaction);
      _chatMessages.add({'type': 'system', 'transaction': newTransaction});
      notifyListeners();

      // 2. Try to sync to Supabase
      try {
        await _supabase
            .from('transactions')
            .insert(newTransaction.toSupabase(user.id));
        
        await _localDb.markAsSynced(newTransaction.id);
      } catch (e) {
        debugPrint('Offline: Error saving transaction to Supabase, will sync later: $e');
      }
    } else {
      // No-auth fallback: still save to local but user_id is empty or guest
      await _localDb.insertTransaction(newTransaction, 'guest', isSynced: false);
      _transactions.add(newTransaction);
      _chatMessages.add({'type': 'system', 'transaction': newTransaction});
      notifyListeners();
    }
  }

  Future<void> syncUnsyncedTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final unsynced = await _localDb.getUnsyncedTransactions();
    if (unsynced.isEmpty) return;

    debugPrint('Syncing ${unsynced.length} unsynced transactions...');

    for (var map in unsynced) {
      try {
        final id = map['id'];
        // Use the map directly as it closely matches Supabase format after adjustments
        // or recreate the model to use toSupabase()
        final transaction = _transactions.firstWhere((t) => t.id == id);
        
        await _supabase
            .from('transactions')
            .upsert(transaction.toSupabase(user.id));
        
        await _localDb.markAsSynced(id);
      } catch (e) {
        debugPrint('Sync failed for transaction ${map['id']}: $e');
        break; // Stop syncing if error occurs (likely still offline)
      }
    }
    
    // Refresh to ensure everything is up to date
    await fetchTransactions();
  }

  Future<void> clearAll() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('transactions').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Error clearing transactions from Supabase: $e');
      }
    }
    await _localDb.clearAll();
    _chatMessages.clear();
    _transactions.clear();
    notifyListeners();
  }
}
