import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../features/expenses/models/transaction_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  static Database? _database;

  LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            amount REAL,
            category TEXT,
            type TEXT,
            tags TEXT,
            people_count INTEGER,
            raw_message TEXT,
            date TEXT,
            user_id TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> insertTransaction(TransactionModel transaction, String userId, {bool isSynced = false}) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category,
        'type': transaction.type.toString().split('.').last,
        'tags': jsonEncode(transaction.tags),
        'people_count': transaction.peopleCount,
        'raw_message': transaction.rawMessage,
        'date': transaction.date.toIso8601String(),
        'user_id': userId,
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await database;
    return await db.query('transactions', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'],
        amount: maps[i]['amount'],
        category: maps[i]['category'],
        type: TransactionType.values.firstWhere(
          (e) => e.toString().split('.').last == maps[i]['type'],
          orElse: () => TransactionType.spent,
        ),
        date: DateTime.parse(maps[i]['date']),
        rawMessage: maps[i]['raw_message'],
        tags: List<String>.from(jsonDecode(maps[i]['tags'])),
        peopleCount: maps[i]['people_count'],
      );
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}
