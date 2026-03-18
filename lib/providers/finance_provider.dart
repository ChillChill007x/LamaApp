import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/savings_goal_model.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

class FinanceProvider with ChangeNotifier {
  List<Wallet> _wallets = [];
  List<TransactionItem> _transactions = [];
  List<TaskItem> _tasks = [];
  List<RecurringRule> _recurringRules = [];
  List<SavingsGoal> _savingsGoals = [];

  double _totalBalance = 0.0;
  double _monthlyExpense = 0.0;
  double _dailyExpense = 0.0;
  double _totalIncomeMonth = 0.0;

  // ─── Getters ──────────────────────────────────────────
  List<Wallet> get wallets => _wallets;
  List<TransactionItem> get transactions => _transactions;
  List<TaskItem> get tasks => _tasks;
  List<RecurringRule> get recurringRules => _recurringRules;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<SavingsGoal> get activeSavingsGoals =>
      _savingsGoals.where((g) => !g.isCompleted).toList();

  List<RecurringRule> getRulesForWallet(int walletId) =>
      _recurringRules.where((r) => r.walletId == walletId).toList();

  List<TaskItem> get pendingTasks {
    final list = _tasks
        .where((t) => t.status == 'pending' || t.status == 'overdue')
        .toList();
    list.sort((a, b) {
      if (a.status == 'overdue' && b.status != 'overdue') return -1;
      if (b.status == 'overdue' && a.status != 'overdue') return 1;
      return a.deadline.compareTo(b.deadline);
    });
    return list;
  }

  List<TaskItem> get doneTasks {
    final list = _tasks.where((t) => t.status == 'done').toList();
    list.sort((a, b) => b.deadline.compareTo(a.deadline));
    return list;
  }

  double get totalBalance => _totalBalance;
  double get monthlyExpense => _monthlyExpense;
  double get dailyExpense => _dailyExpense;
  double get totalIncomeMonth => _totalIncomeMonth;

  Map<DateTime, String> get taskDeadlineMap {
    final map = <DateTime, String>{};
    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.status == 'done') continue;
      final day = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
      final isOverdue = task.deadline.isBefore(now);
      if (!map.containsKey(day) || isOverdue) {
        map[day] = isOverdue ? 'overdue' : 'pending';
      }
    }
    return map;
  }

  // ─── Budget helpers ───────────────────────────────────
  double getMonthlyExpenseByWallet(int walletId) {
    final now = DateTime.now();
    return _transactions
        .where((tx) =>
            tx.walletId == walletId &&
            tx.type == 'expense' &&
            tx.dateTime.year == now.year &&
            tx.dateTime.month == now.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getBudgetUsageRatio(int walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(id: 0, name: '', initialBalance: 0, emojiIcon: ''),
    );
    if (wallet.monthlyBudget == null || wallet.monthlyBudget! <= 0) return 0;
    return getMonthlyExpenseByWallet(walletId) / wallet.monthlyBudget!;
  }

  BudgetStatus getBudgetStatus(int walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(id: 0, name: '', initialBalance: 0, emojiIcon: ''),
    );
    final balance = getWalletBalance(walletId);
    if (wallet.lowBalanceThreshold != null && balance < wallet.lowBalanceThreshold!) {
      return BudgetStatus.exceeded;
    }
    if (wallet.monthlyBudget == null) return BudgetStatus.none;
    final ratio = getBudgetUsageRatio(walletId);
    final threshold = (wallet.alertPercent ?? 80) / 100;
    if (ratio >= 1.0) return BudgetStatus.exceeded;
    if (ratio >= threshold) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }

  String getBudgetBadgeText(int walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(id: 0, name: '', initialBalance: 0, emojiIcon: ''),
    );
    final balance = getWalletBalance(walletId);
    if (wallet.lowBalanceThreshold != null && balance < wallet.lowBalanceThreshold!) {
      return 'เหลือน้อย';
    }
    if (wallet.monthlyBudget == null) return '';
    final ratio = getBudgetUsageRatio(walletId);
    if (ratio >= 1.0) return 'เกินงบ!';
    final threshold = (wallet.alertPercent ?? 80) / 100;
    if (ratio >= threshold) return '${(ratio * 100).toStringAsFixed(0)}%';
    return '';
  }

  // ─── Clear local data ของ user ปัจจุบัน ───────────────
  Future<void> clearLocalData() async {
    _wallets = []; _transactions = []; _tasks = [];
    _recurringRules = []; _savingsGoals = [];
    _totalBalance = 0; _monthlyExpense = 0;
    _dailyExpense = 0; _totalIncomeMonth = 0;
    await DBHelper().clearAllData();
    notifyListeners();
  }

  // ─── Load ─────────────────────────────────────────────
  Future<void> loadData() async {
    _wallets = await DBHelper().getWallets();
    _transactions = await DBHelper().getTransactions();
    _tasks = await DBHelper().getTasks();
    _recurringRules = await DBHelper().getRecurringRules();
    _savingsGoals = await DBHelper().getSavingsGoals();
    await _processRecurringRules();
    _autoUpdateOverdueTasks();
    _calculateSummaries();
    notifyListeners();
    _checkAllBudgetAlerts();
    // auto-push background (ไม่บล็อก UI)
    SyncService().pushToCloud();
  }

  void _autoUpdateOverdueTasks() {
    final now = DateTime.now();
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.status == 'pending' && task.deadline.isBefore(now)) {
        _tasks[i] = task.copyWith(status: 'overdue');
        DBHelper().updateTask(_tasks[i]);
      }
    }
  }

  Future<void> _processRecurringRules() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool anyRan = false;
    for (int i = 0; i < _recurringRules.length; i++) {
      final rule = _recurringRules[i];
      if (!rule.isActive || !_shouldRunToday(rule, today)) continue;
      final tx = TransactionItem(
        walletId: rule.walletId,
        type: rule.txType,         // ✅ รองรับทั้ง income และ expense
        amount: rule.amount,
        category: rule.category,
        dateTime: now,
        note: '${rule.label} (อัตโนมัติ)',
      );
      await DBHelper().insertTransaction(tx);
      final updated = rule.copyWith(lastRunAt: today);
      await DBHelper().updateRecurringRule(updated);
      _recurringRules[i] = updated;
      anyRan = true;

      // แจ้งเตือน recurring expense
      if (rule.txType == 'expense') {
        await NotificationService().sendRecurringExpenseAlert(
          walletId: rule.walletId,
          label: rule.label,
          amount: rule.amount,
        );
      }
    }
    if (anyRan) _transactions = await DBHelper().getTransactions();
  }

  bool _shouldRunToday(RecurringRule rule, DateTime today) {
    final last = rule.lastRunAt != null
        ? DateTime(rule.lastRunAt!.year, rule.lastRunAt!.month, rule.lastRunAt!.day)
        : null;
    if (last != null && last == today) return false;
    switch (rule.frequency) {
      case 'daily':   return true;
      case 'weekly':  return today.weekday == rule.dayValue;
      case 'monthly':
        final lastDay = DateTime(today.year, today.month + 1, 0).day;
        return today.day == (rule.dayValue > lastDay ? lastDay : rule.dayValue);
      default: return false;
    }
  }

  Future<void> _checkAllBudgetAlerts() async {
    for (final wallet in _wallets) {
      if (wallet.id == null) continue;
      final balance = getWalletBalance(wallet.id!);
      final spent = getMonthlyExpenseByWallet(wallet.id!);
      if (wallet.monthlyBudget != null && wallet.monthlyBudget! > 0) {
        final ratio = spent / wallet.monthlyBudget!;
        final threshold = (wallet.alertPercent ?? 80) / 100;
        if (ratio >= threshold) {
          await NotificationService().sendBudgetAlert(
            walletId: wallet.id!, walletName: wallet.name, emoji: wallet.emojiIcon,
            spent: spent, budget: wallet.monthlyBudget!, isExceeded: ratio >= 1.0,
          );
        }
      }
      if (wallet.lowBalanceThreshold != null && balance < wallet.lowBalanceThreshold!) {
        await NotificationService().sendLowBalanceAlert(
          walletId: wallet.id!, walletName: wallet.name, emoji: wallet.emojiIcon,
          balance: balance, threshold: wallet.lowBalanceThreshold!,
        );
      }
    }
  }

  // ─── Wallet CRUD ──────────────────────────────────────
  Future<void> addWallet(Wallet wallet) async {
    await DBHelper().insertWallet(wallet);
    await loadData();
  }

  Future<void> updateWallet(Wallet wallet) async {
    try {
      await DBHelper().updateWallet(wallet);
      final index = _wallets.indexWhere((w) => w.id == wallet.id);
      if (index != -1) {
        _wallets[index] = wallet;
        _calculateSummaries();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating wallet: $e');
    }
  }

  Future<void> deleteWallet(int id) async {
    final orphaned = _transactions.where((tx) => tx.walletId == id).toList();
    for (var tx in orphaned) {
      if (tx.id != null) await DBHelper().deleteTransaction(tx.id!);
    }
    await DBHelper().deleteWallet(id);
    await loadData();
  }

  // ─── Transaction CRUD ─────────────────────────────────
  Future<void> addTransaction(TransactionItem transaction) async {
    await DBHelper().insertTransaction(transaction);
    await loadData();
  }

  Future<void> updateTransaction(TransactionItem transaction) async {
    await DBHelper().updateTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await DBHelper().deleteTransaction(id);
    await loadData();
  }

  // ─── Transfer between wallets ─────────────────────────
  /// โอนเงินจากกระเป๋า from ไป to
  Future<void> transfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    String? note,
  }) async {
    final now = DateTime.now();

    final fromWallet = _wallets.firstWhere((w) => w.id == fromWalletId);
    final toWallet   = _wallets.firstWhere((w) => w.id == toWalletId);

    // รายจ่ายจากกระเป๋าต้นทาง
    await DBHelper().insertTransaction(TransactionItem(
      walletId: fromWalletId,
      type: 'expense',
      amount: amount,
      category: '💸 โอนไป ${toWallet.name}',
      dateTime: now,
      note: note,
    ));

    // รายรับเข้ากระเป๋าปลายทาง
    await DBHelper().insertTransaction(TransactionItem(
      walletId: toWalletId,
      type: 'income',
      amount: amount,
      category: '💸 รับจาก ${fromWallet.name}',
      dateTime: now,
      note: note,
    ));

    await loadData();
  }

  // ─── Savings Goal CRUD ────────────────────────────────
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await DBHelper().insertSavingsGoal(goal);
    _savingsGoals = await DBHelper().getSavingsGoals();
    notifyListeners();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await DBHelper().updateSavingsGoal(goal);
    final index = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _savingsGoals[index] = goal;
      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(int id) async {
    await DBHelper().deleteSavingsGoal(id);
    _savingsGoals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// เพิ่มเงินออมเข้าเป้าหมาย (บันทึกเป็น transaction ด้วย)
  Future<void> addSaving({
    required SavingsGoal goal,
    required double amount,
  }) async {
    final newSaved = goal.savedAmount + amount;
    final isCompleted = newSaved >= goal.targetAmount;

    // บันทึก transaction รายจ่าย (เงินออก)
    await DBHelper().insertTransaction(TransactionItem(
      walletId: goal.walletId,
      type: 'expense',
      amount: amount,
      category: '🎯 ออม: ${goal.title}',
      dateTime: DateTime.now(),
    ));

    // อัปเดต savings goal
    final updated = goal.copyWith(
      savedAmount: newSaved,
      isCompleted: isCompleted,
    );
    await DBHelper().updateSavingsGoal(updated);

    await loadData();
  }

  // ─── Recurring CRUD ───────────────────────────────────
  Future<void> addRecurringRule(RecurringRule rule) async {
    final id = await DBHelper().insertRecurringRule(rule);
    _recurringRules.add(rule.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    await DBHelper().updateRecurringRule(rule);
    final index = _recurringRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _recurringRules[index] = rule;
      notifyListeners();
    }
  }

  Future<void> deleteRecurringRule(int id) async {
    await DBHelper().deleteRecurringRule(id);
    _recurringRules.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> toggleRecurringRule(int id) async {
    final index = _recurringRules.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final updated = _recurringRules[index].copyWith(
        isActive: !_recurringRules[index].isActive);
    await DBHelper().updateRecurringRule(updated);
    _recurringRules[index] = updated;
    notifyListeners();
  }

  // ─── Task CRUD ────────────────────────────────────────
  Future<void> addTask(TaskItem task) async {
    final id = await DBHelper().insertTask(task);
    // แจ้งเตือนก่อน deadline 1 วัน (default)
    await NotificationService().scheduleTaskReminder(task.copyWith(id: id));
    await loadData();
  }

  /// เพิ่มงานพร้อมกำหนดเวลาแจ้งเตือนเอง
  Future<void> addTaskWithNotify(TaskItem task, DateTime notifyAt) async {
    final id = await DBHelper().insertTask(task);
    final taskWithId = task.copyWith(id: id);
    await NotificationService().scheduleTaskReminderAt(taskWithId, notifyAt);
    await loadData();
  }

  Future<void> updateTask(TaskItem task) async {
    await DBHelper().updateTask(task);
    if (task.id != null) {
      await NotificationService().cancelTaskReminder(task.id!);
      if (task.status != 'done') {
        await NotificationService().scheduleTaskReminder(task);
      }
    }
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  /// แก้ไขงานพร้อมกำหนดเวลาแจ้งเตือนเอง
  Future<void> updateTaskWithNotify(TaskItem task, DateTime notifyAt) async {
    await DBHelper().updateTask(task);
    if (task.id != null) {
      await NotificationService().cancelTaskReminder(task.id!);
      if (task.status != 'done') {
        await NotificationService().scheduleTaskReminderAt(task, notifyAt);
      }
    }
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    await DBHelper().deleteTask(id);
    await NotificationService().cancelTaskReminder(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> markTaskDone(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(status: 'done');
    await DBHelper().updateTask(updated);
    await NotificationService().cancelTaskReminder(id);
    _tasks[index] = updated;
    notifyListeners();
  }

  Future<void> markTaskPending(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final task = _tasks[index];
    final updated = task.copyWith(
      status: task.deadline.isBefore(DateTime.now()) ? 'overdue' : 'pending',
    );
    await DBHelper().updateTask(updated);
    await NotificationService().scheduleTaskReminder(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  // ─── Summary ──────────────────────────────────────────
  void _calculateSummaries() {
    _totalBalance = 0.0;
    _monthlyExpense = 0.0;
    _dailyExpense = 0.0;
    _totalIncomeMonth = 0.0;
    final now = DateTime.now();
    for (var w in _wallets) _totalBalance += w.initialBalance;
    for (var tx in _transactions) {
      final isThisMonth =
          tx.dateTime.year == now.year && tx.dateTime.month == now.month;
      final isToday = isThisMonth && tx.dateTime.day == now.day;
      if (tx.type == 'income') {
        _totalBalance += tx.amount;
        if (isThisMonth) _totalIncomeMonth += tx.amount;
      } else {
        _totalBalance -= tx.amount;
        if (isThisMonth) _monthlyExpense += tx.amount;
        if (isToday) _dailyExpense += tx.amount;
      }
    }
  }

  double getWalletBalance(int walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(id: 0, name: '', initialBalance: 0, emojiIcon: ''),
    );
    double balance = wallet.initialBalance;
    for (var tx in _transactions.where((tx) => tx.walletId == walletId)) {
      balance += tx.type == 'income' ? tx.amount : -tx.amount;
    }
    return balance;
  }
}

enum BudgetStatus { none, ok, warning, exceeded }
