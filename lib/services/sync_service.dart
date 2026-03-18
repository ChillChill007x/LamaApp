import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';
import '../models/savings_goal_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/category_model.dart';

/// Strategy: Local-first
/// - เขียนลง SQLite ก่อนเสมอ (ทำงาน offline ได้)
/// - sync ขึ้น Supabase เมื่อมีอินเทอร์เน็ต
/// - ดึงข้อมูลจาก Supabase เมื่อ login ครั้งแรกหรือ login ใหม่
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  String? get _uid => _supabase.auth.currentUser?.id;

  // ─── Full sync: ดึงจาก Supabase ลงมาเก็บ local ─────
  /// เรียกตอน login ครั้งแรก หรือ เปิดแอปหลัง login
  Future<void> pullFromCloud() async {
    if (_uid == null) return;
    try {
      await _pullWallets();
      await _pullTransactions();
      await _pullTasks();
      await _pullSavingsGoals();
      await _pullRecurringRules();
      await _pullCategories();
      debugPrint('[Sync] Pull complete');
    } catch (e) {
      debugPrint('[Sync] Pull error: $e');
    }
  }

  // ─── Push: อัปโหลดข้อมูล local ขึ้น Supabase ────────
  Future<void> pushToCloud() async {
    if (_uid == null || _isSyncing) return;
    _isSyncing = true;
    try {
      await _pushWallets();
      await _pushTransactions();
      await _pushTasks();
      await _pushSavingsGoals();
      await _pushRecurringRules();
      await _pushCategories();
      debugPrint('[Sync] Push complete');
    } catch (e) {
      debugPrint('[Sync] Push error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ════════════════════════════════════════════════════
  // PULL — Supabase → SQLite
  // ════════════════════════════════════════════════════

  Future<void> _pullWallets() async {
    final rows = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false);

    final db = DBHelper();
    final existing = await db.getWallets();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      final wallet = Wallet(
        id: localId,
        name: row['name'],
        emojiIcon: row['emoji_icon'] ?? '💰',
        initialBalance: (row['initial_balance'] as num).toDouble(),
        note: row['note'],
        monthlyBudget: (row['monthly_budget'] as num?)?.toDouble(),
        alertPercent: (row['alert_percent'] as num?)?.toDouble(),
        lowBalanceThreshold: (row['low_balance_threshold'] as num?)?.toDouble(),
      );

      if (localId != null && existing.any((w) => w.id == localId)) {
        await db.updateWallet(wallet);
      } else if (localId == null) {
        // สร้างใหม่ local แล้วอัปเดต local_id กลับ
        final newId = await db.insertWallet(wallet);
        await _supabase.from('wallets')
            .update({'local_id': newId})
            .eq('id', row['id']);
      }
    }
  }

  Future<void> _pullTransactions() async {
    final rows = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false)
        .order('date_time', ascending: false);

    final db = DBHelper();
    final existing = await db.getTransactions();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      if (localId != null && existing.any((t) => t.id == localId)) continue;

      final walletLocalId = await _getWalletLocalId(row['wallet_id']);
      if (walletLocalId == null) continue;

      final tx = TransactionItem(
        id: localId,
        walletId: walletLocalId,
        type: row['type'],
        amount: (row['amount'] as num).toDouble(),
        category: row['category'],
        dateTime: DateTime.parse(row['date_time']),
        note: row['note'],
      );
      final newId = await db.insertTransaction(tx);
      await _supabase.from('transactions')
          .update({'local_id': newId})
          .eq('id', row['id']);
    }
  }

  Future<void> _pullTasks() async {
    final rows = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false);

    final db = DBHelper();
    final existing = await db.getTasks();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      if (localId != null && existing.any((t) => t.id == localId)) continue;
      final task = TaskItem(
        id: localId,
        title: row['title'],
        deadline: DateTime.parse(row['deadline']),
        status: row['status'] ?? 'pending',
        note: row['note'],
        createdAt: DateTime.parse(row['created_at']),
      );
      final newId = await db.insertTask(task);
      await _supabase.from('tasks')
          .update({'local_id': newId}).eq('id', row['id']);
    }
  }

  Future<void> _pullSavingsGoals() async {
    final rows = await _supabase
        .from('savings_goals')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false);

    final db = DBHelper();
    final existing = await db.getSavingsGoals();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      if (localId != null && existing.any((g) => g.id == localId)) continue;
      final walletLocalId = await _getWalletLocalId(row['wallet_id'] ?? '');
      if (walletLocalId == null) continue;
      final goal = SavingsGoal(
        id: localId,
        title: row['title'],
        emoji: row['emoji'] ?? '🎯',
        targetAmount: (row['target_amount'] as num).toDouble(),
        savedAmount: (row['saved_amount'] as num).toDouble(),
        deadline: DateTime.parse(row['deadline']),
        walletId: walletLocalId,
        isCompleted: row['is_completed'] ?? false,
      );
      final newId = await db.insertSavingsGoal(goal);
      await _supabase.from('savings_goals')
          .update({'local_id': newId}).eq('id', row['id']);
    }
  }

  Future<void> _pullRecurringRules() async {
    final rows = await _supabase
        .from('recurring_rules')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false);

    final db = DBHelper();
    final existing = await db.getRecurringRules();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      if (localId != null && existing.any((r) => r.id == localId)) continue;
      final walletLocalId = await _getWalletLocalId(row['wallet_id'] ?? '');
      if (walletLocalId == null) continue;
      final rule = RecurringRule(
        id: localId,
        walletId: walletLocalId,
        label: row['label'],
        amount: (row['amount'] as num).toDouble(),
        category: row['category'],
        frequency: row['frequency'],
        dayValue: row['day_value'],
        isActive: row['is_active'] ?? true,
        txType: row['tx_type'] ?? 'income',
        lastRunAt: row['last_run_at'] != null
            ? DateTime.parse(row['last_run_at']) : null,
      );
      final newId = await db.insertRecurringRule(rule);
      await _supabase.from('recurring_rules')
          .update({'local_id': newId}).eq('id', row['id']);
    }
  }

  Future<void> _pullCategories() async {
    final rows = await _supabase
        .from('categories')
        .select()
        .eq('user_id', _uid!)
        .eq('is_deleted', false);

    final db = DBHelper();
    final existing = await db.getCategories();
    for (final row in rows) {
      final localId = row['local_id'] as int?;
      if (localId != null && existing.any((c) => c.id == localId)) continue;
      final cat = CategoryItem(
        id: localId,
        name: row['name'],
        emoji: row['emoji'] ?? '📦',
        type: row['type'] ?? 'expense',
        isDefault: row['is_default'] ?? false,
        sortOrder: row['sort_order'] ?? 0,
      );
      final newId = await db.insertCategory(cat);
      await _supabase.from('categories')
          .update({'local_id': newId}).eq('id', row['id']);
    }
  }

  // ════════════════════════════════════════════════════
  // PUSH — SQLite → Supabase (delete existing + insert fresh)
  // ════════════════════════════════════════════════════

  Future<void> _pushWallets() async {
    final wallets = await DBHelper().getWallets();
    if (wallets.isEmpty) return;

    final rows = wallets.map((w) => {
      'local_id': w.id,
      'user_id': _uid,
      'name': w.name,
      'emoji_icon': w.emojiIcon,
      'initial_balance': w.initialBalance,
      'note': w.note,
      'monthly_budget': w.monthlyBudget,
      'alert_percent': w.alertPercent,
      'low_balance_threshold': w.lowBalanceThreshold,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();

    await _supabase.from('wallets')
        .delete().eq('user_id', _uid!);
    await _supabase.from('wallets').insert(rows);
  }

  Future<void> _pushTransactions() async {
    final txs = await DBHelper().getTransactions();
    if (txs.isEmpty) return;

    final walletIdMap = await _buildWalletIdMap();
    final rows = txs.where((tx) => walletIdMap.containsKey(tx.walletId))
        .map((tx) => {
      'local_id': tx.id,
      'user_id': _uid,
      'wallet_id': walletIdMap[tx.walletId],
      'type': tx.type,
      'amount': tx.amount,
      'category': tx.category,
      'date_time': tx.dateTime.toIso8601String(),
      'note': tx.note,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();

    if (rows.isEmpty) return;
    await _supabase.from('transactions')
        .delete().eq('user_id', _uid!);
    await _supabase.from('transactions').insert(rows);
  }

  Future<void> _pushTasks() async {
    final tasks = await DBHelper().getTasks();
    if (tasks.isEmpty) return;
    final rows = tasks.map((t) => {
      'local_id': t.id,
      'user_id': _uid,
      'title': t.title,
      'deadline': t.deadline.toIso8601String(),
      'status': t.status,
      'note': t.note,
      'created_at': t.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();
    await _supabase.from('tasks').delete().eq('user_id', _uid!);
    await _supabase.from('tasks').insert(rows);
  }

  Future<void> _pushSavingsGoals() async {
    final goals = await DBHelper().getSavingsGoals();
    if (goals.isEmpty) return;
    final walletIdMap = await _buildWalletIdMap();
    final rows = goals.where((g) => walletIdMap.containsKey(g.walletId))
        .map((g) => {
      'local_id': g.id,
      'user_id': _uid,
      'wallet_id': walletIdMap[g.walletId],
      'title': g.title,
      'emoji': g.emoji,
      'target_amount': g.targetAmount,
      'saved_amount': g.savedAmount,
      'deadline': g.deadline.toIso8601String(),
      'is_completed': g.isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();
    if (rows.isEmpty) return;
    await _supabase.from('savings_goals').delete().eq('user_id', _uid!);
    await _supabase.from('savings_goals').insert(rows);
  }

  Future<void> _pushRecurringRules() async {
    final rules = await DBHelper().getRecurringRules();
    if (rules.isEmpty) return;
    final walletIdMap = await _buildWalletIdMap();
    final rows = rules.where((r) => walletIdMap.containsKey(r.walletId))
        .map((r) => {
      'local_id': r.id,
      'user_id': _uid,
      'wallet_id': walletIdMap[r.walletId],
      'label': r.label,
      'amount': r.amount,
      'category': r.category,
      'frequency': r.frequency,
      'day_value': r.dayValue,
      'is_active': r.isActive,
      'tx_type': r.txType,
      'last_run_at': r.lastRunAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();
    if (rows.isEmpty) return;
    await _supabase.from('recurring_rules').delete().eq('user_id', _uid!);
    await _supabase.from('recurring_rules').insert(rows);
  }

  Future<void> _pushCategories() async {
    final cats = await DBHelper().getCategories();
    if (cats.isEmpty) return;
    final rows = cats.map((c) => {
      'local_id': c.id,
      'user_id': _uid,
      'name': c.name,
      'emoji': c.emoji,
      'type': c.type,
      'is_default': c.isDefault,
      'sort_order': c.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    }).toList();
    await _supabase.from('categories').delete().eq('user_id', _uid!);
    await _supabase.from('categories').insert(rows);
  }

  // ── Helpers ───────────────────────────────────────────
  Future<int?> _getWalletLocalId(String cloudWalletId) async {
    if (cloudWalletId.isEmpty) return null;
    try {
      final row = await _supabase.from('wallets')
          .select('local_id')
          .eq('id', cloudWalletId)
          .single();
      return row['local_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, String>> _buildWalletIdMap() async {
    try {
      final rows = await _supabase.from('wallets')
          .select('id,local_id')
          .eq('user_id', _uid!)
          .not('local_id', 'is', null);
      return {
        for (final r in rows)
          if (r['local_id'] != null) (r['local_id'] as int): r['id'] as String
      };
    } catch (_) {
      return {};
    }
  }
}
