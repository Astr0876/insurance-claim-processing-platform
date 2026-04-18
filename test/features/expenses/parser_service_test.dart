import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/expenses/services/parser_service.dart';
import 'package:lumina/features/expenses/models/transaction_model.dart';

void main() {
  group('NLP Parser Tests', () {
    test('Spent 200 on food', () {
      final tx = ParserService.parseMessage('Spent 200 on food');
      expect(tx.amount, 200.0);
      expect(tx.category, 'Food');
      expect(tx.type, TransactionType.spent);
      expect(tx.effectiveAmount, 200.0);
    });

    test('50 for rickshaw #travel', () {
      final tx = ParserService.parseMessage('50 for rickshaw #travel');
      expect(tx.amount, 50.0);
      expect(tx.category, 'Travel');
      expect(tx.type, TransactionType.spent);
      expect(tx.tags, contains('travel'));
      expect(tx.effectiveAmount, 50.0);
    });

    test('Split 800 with 4 friends', () {
      final tx = ParserService.parseMessage('Split 800 with 4 friends');
      expect(tx.amount, 800.0);
      expect(tx.type, TransactionType.split);
      // "with 4 friends" means 5 total people (user + 4)
      expect(tx.peopleCount, 5);
      expect(tx.effectiveAmount, 160.0);
    });
    
    test('Split 1000 among 4 people', () {
      final tx = ParserService.parseMessage('Split 1000 among 4 people');
      expect(tx.amount, 1000.0);
      expect(tx.type, TransactionType.split);
      // "among 4 people" usually means 4 total (user + 3 or it just means total 4)
      expect(tx.peopleCount, 4);
      expect(tx.effectiveAmount, 250.0);
    });
  });
}
