import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/savings_goal_model.dart';
import '../models/category_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;
  factory DBHelper() => _instance;
  DBHelper._internal();

  // uid ของ user ที่ login อยู่ ถ้าไม่ได้ login = 'offline'
  String get _uid =>
      Supabase.instance.client.auth.currentUser?.id ?? 'offline';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        name TEXT NOT NULL, emojiIcon TEXT NOT NULL,
        initialBalance REAL NOT NULL, note TEXT,
        monthlyBudget REAL, alertPercent REAL, lowBalanceThreshold REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        walletId INTEGER NOT NULL, type TEXT NOT NULL,
        amount REAL NOT NULL, category TEXT NOT NULL,
        dateTime TEXT NOT NULL, note TEXT, imagePath TEXT,
        FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');
    await _createTasksTable(db);
    await _createRecurringTable(db);
    await _createSavingsTable(db);
    await _createCategoriesTable(db);
    await _seedDefaultCategories(db, 'offline');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createTasksTable(db);
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE wallets ADD COLUMN monthlyBudget REAL');
      await db.execute('ALTER TABLE wallets ADD COLUMN alertPercent REAL');
      await db.execute('ALTER TABLE wallets ADD COLUMN lowBalanceThreshold REAL');
    }
    if (oldVersion < 4) await _createRecurringTable(db);
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN imagePath TEXT');
      await _createSavingsTable(db);
    }
    if (oldVersion < 6) {
      try { await db.execute("ALTER TABLE recurring_rules ADD COLUMN txType TEXT NOT NULL DEFAULT 'income'"); } catch (_) {}
      await _createCategoriesTable(db);
      await _seedDefaultCategories(db, 'offline');
    }
    if (oldVersion < 7) {
      // เพิ่ม userId column ในทุกตาราง
      for (final table in ['wallets','transactions','tasks','savings_goals','recurring_rules','categories']) {
        try { await db.execute("ALTER TABLE $table ADD COLUMN userId TEXT NOT NULL DEFAULT 'offline'"); } catch (_) {}
      }
    }
  }

  Future _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        title TEXT NOT NULL, deadline TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT, createdAt TEXT NOT NULL
      )
    ''');
  }

  Future _createRecurringTable(Database db) async {
    await db.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        walletId INTEGER NOT NULL, label TEXT NOT NULL,
        amount REAL NOT NULL, category TEXT NOT NULL,
        frequency TEXT NOT NULL, dayValue INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1, lastRunAt TEXT,
        txType TEXT NOT NULL DEFAULT 'income',
        FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createSavingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        title TEXT NOT NULL, emoji TEXT NOT NULL DEFAULT '🎯',
        targetAmount REAL NOT NULL, savedAmount REAL NOT NULL DEFAULT 0,
        deadline TEXT NOT NULL, walletId INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT 'offline',
        name TEXT NOT NULL, emoji TEXT NOT NULL DEFAULT '📦',
        type TEXT NOT NULL DEFAULT 'expense',
        isDefault INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _seedDefaultCategories(Database db, String uid) async {
    for (final cat in CategoryItem.defaults) {
      await db.insert('categories', {...cat.toMap(), 'userId': uid});
    }
  }

  // ════════════════════════════════════════════════════
  // WALLET
  // ════════════════════════════════════════════════════
  Future<int> insertWallet(Wallet w) async {
    final map = {...w.toMap(), 'userId': _uid};
    return (await database).insert('wallets', map);
  }

  Future<List<Wallet>> getWallets() async {
    final maps = await (await database)
        .query('wallets', where: 'userId = ?', whereArgs: [_uid]);
    return maps.map((m) => Wallet.fromMap(m)).toList();
  }

  Future<int> updateWallet(Wallet w) async =>
      (await database).update('wallets', {...w.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [w.id, _uid]);

  Future<int> deleteWallet(int id) async =>
      (await database).delete('wallets',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // TRANSACTION
  // ════════════════════════════════════════════════════
  Future<int> insertTransaction(TransactionItem t) async {
    final map = {...t.toMap(), 'userId': _uid};
    return (await database).insert('transactions', map);
  }

  Future<List<TransactionItem>> getTransactions() async {
    final maps = await (await database).query('transactions',
        where: 'userId = ?', whereArgs: [_uid], orderBy: 'dateTime DESC');
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionItem t) async =>
      (await database).update('transactions', {...t.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [t.id, _uid]);

  Future<int> deleteTransaction(int id) async =>
      (await database).delete('transactions',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // TASK
  // ════════════════════════════════════════════════════
  Future<int> insertTask(TaskItem t) async {
    final map = {...t.toMap(), 'userId': _uid};
    return (await database).insert('tasks', map);
  }

  Future<List<TaskItem>> getTasks() async {
    final maps = await (await database).query('tasks',
        where: 'userId = ?', whereArgs: [_uid], orderBy: 'deadline ASC');
    return maps.map((m) => TaskItem.fromMap(m)).toList();
  }

  Future<int> updateTask(TaskItem t) async =>
      (await database).update('tasks', {...t.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [t.id, _uid]);

  Future<int> deleteTask(int id) async =>
      (await database).delete('tasks',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // RECURRING RULE
  // ════════════════════════════════════════════════════
  Future<int> insertRecurringRule(RecurringRule r) async {
    final map = {...r.toMap(), 'userId': _uid};
    return (await database).insert('recurring_rules', map);
  }

  Future<List<RecurringRule>> getRecurringRules() async {
    final maps = await (await database).query('recurring_rules',
        where: 'userId = ?', whereArgs: [_uid]);
    return maps.map((m) => RecurringRule.fromMap(m)).toList();
  }

  Future<int> updateRecurringRule(RecurringRule r) async =>
      (await database).update('recurring_rules', {...r.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [r.id, _uid]);

  Future<int> deleteRecurringRule(int id) async =>
      (await database).delete('recurring_rules',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // SAVINGS GOAL
  // ════════════════════════════════════════════════════
  Future<int> insertSavingsGoal(SavingsGoal g) async {
    final map = {...g.toMap(), 'userId': _uid};
    return (await database).insert('savings_goals', map);
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final maps = await (await database).query('savings_goals',
        where: 'userId = ?', whereArgs: [_uid]);
    return maps.map((m) => SavingsGoal.fromMap(m)).toList();
  }

  Future<int> updateSavingsGoal(SavingsGoal g) async =>
      (await database).update('savings_goals', {...g.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [g.id, _uid]);

  Future<int> deleteSavingsGoal(int id) async =>
      (await database).delete('savings_goals',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // CATEGORY
  // ════════════════════════════════════════════════════
  Future<int> insertCategory(CategoryItem c) async {
    final map = {...c.toMap(), 'userId': _uid};
    return (await database).insert('categories', map);
  }

  Future<List<CategoryItem>> getCategories() async {
    final maps = await (await database).query('categories',
        where: 'userId = ?', whereArgs: [_uid],
        orderBy: 'sortOrder ASC, name ASC');
    return maps.map((m) => CategoryItem.fromMap(m)).toList();
  }

  Future<int> updateCategory(CategoryItem c) async =>
      (await database).update('categories', {...c.toMap(), 'userId': _uid},
          where: 'id = ? AND userId = ?', whereArgs: [c.id, _uid]);

  Future<int> deleteCategory(int id) async =>
      (await database).delete('categories',
          where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);

  // ════════════════════════════════════════════════════
  // CLEAR — ลบเฉพาะข้อมูลของ user ที่ระบุ
  // ════════════════════════════════════════════════════
  Future<void> clearUserData(String uid) async {
    final db = await database;
    await db.delete('transactions', where: 'userId = ?', whereArgs: [uid]);
    await db.delete('savings_goals', where: 'userId = ?', whereArgs: [uid]);
    await db.delete('recurring_rules', where: 'userId = ?', whereArgs: [uid]);
    await db.delete('tasks', where: 'userId = ?', whereArgs: [uid]);
    await db.delete('categories', where: 'userId = ?', whereArgs: [uid]);
    await db.delete('wallets', where: 'userId = ?', whereArgs: [uid]);
    // seed categories ใหม่สำหรับ user นั้น
    await _seedDefaultCategories(db, uid);
  }

  // ลบทุก user (backward compat)
  Future<void> clearAllData() async {
    await clearUserData(_uid);
  }
}
