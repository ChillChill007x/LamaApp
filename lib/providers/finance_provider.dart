import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../database/db_helper.dart';

class FinanceProvider with ChangeNotifier {
  List<Wallet> _wallets = [];
  List<TransactionItem> _transactions = [];

  // ตัวแปรสำหรับสรุปยอดหน้าภาพรวม
  double _totalBalance = 0.0;     // คงเหลือ (รวมเงินต้นของทุกกระเป๋า + รายรับ - รายจ่าย)
  double _monthlyExpense = 0.0;   // รอบเดือน (รายจ่ายเฉพาะเดือนปัจจุบัน)
  double _dailyExpense = 0.0;     // รายวัน (รายจ่ายเฉพาะวันนี้)
  double _totalIncomeMonth = 0.0; // รายรับรวม (รายรับเฉพาะเดือนปัจจุบัน)

  // Getters เพื่อให้หน้าจอ UI ดึงค่าไปแสดงผล
  List<Wallet> get wallets => _wallets;
  List<TransactionItem> get transactions => _transactions;
  double get totalBalance => _totalBalance;
  double get monthlyExpense => _monthlyExpense;
  double get dailyExpense => _dailyExpense;
  double get totalIncomeMonth => _totalIncomeMonth;

  // โหลดข้อมูลทั้งหมดเมื่อเปิดแอป
  Future<void> loadData() async {
    _wallets = await DBHelper().getWallets();
    _transactions = await DBHelper().getTransactions();
    
    _calculateSummaries();
    notifyListeners(); // สั่งให้ UI อัปเดตตัวเอง
  }

  // ==========================================
  // จัดการกระเป๋าตัง (Wallet)
  // ==========================================
  
  // 🟢 เพิ่มกระเป๋าตังใหม่
  Future<void> addWallet(Wallet wallet) async {
    await DBHelper().insertWallet(wallet);
    await loadData(); // รีโหลดข้อมูลใหม่และคำนวณยอดใหม่
  }

  // 🔵 อัปเดตข้อมูลกระเป๋าตัง (แก้ไขบันทึกช่วยจำ, ชื่อ, หรือไอคอน)
  Future<void> updateWallet(Wallet wallet) async {
    try {
      await DBHelper().updateWallet(wallet);
      // หาตำแหน่งใน List เพื่ออัปเดตค่าทันทีใน Memory
      final index = _wallets.indexWhere((w) => w.id == wallet.id);
      if (index != -1) {
        _wallets[index] = wallet;
        _calculateSummaries(); // คำนวณยอดใหม่เผื่อเงินตั้งต้นเปลี่ยน
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating wallet: $e");
    }
  }

  // 🔴 ลบกระเป๋าตัง
  Future<void> deleteWallet(int id) async {
    // 1. ค้นหาธุรกรรมทั้งหมดที่เป็นของกระเป๋าใบนี้ แล้วสั่งลบทิ้งทีละรายการ
    // (หากเปิด PRAGMA foreign_keys = ON ใน DBHelper ตรงนี้จะไม่ต้องวนลบเองครับ)
    final orphanedTransactions = _transactions.where((tx) => tx.walletId == id).toList();
    for (var tx in orphanedTransactions) {
      if (tx.id != null) {
        await DBHelper().deleteTransaction(tx.id!);
      }
    }

    // 2. เมื่อลบธุรกรรมลูกข่ายหมดแล้ว ค่อยลบตัวกระเป๋าหลักทิ้ง
    await DBHelper().deleteWallet(id);
    
    // 3. โหลดข้อมูลใหม่ทั้งหมด
    await loadData();
  }

  // ==========================================
  // จัดการรายการธุรกรรม (Transaction)
  // ==========================================
  
  Future<void> addTransaction(TransactionItem transaction) async {
    await DBHelper().insertTransaction(transaction);
    await loadData(); 
  }

  Future<void> deleteTransaction(int id) async {
    await DBHelper().deleteTransaction(id);
    await loadData();
  }

  // ==========================================
  // ระบบคำนวณยอดสรุป
  // ==========================================
  void _calculateSummaries() {
    _totalBalance = 0.0;
    _monthlyExpense = 0.0;
    _dailyExpense = 0.0;
    _totalIncomeMonth = 0.0;

    DateTime now = DateTime.now();

    // 1. นำเงินตั้งต้นของทุกกระเป๋ามารวมเป็นยอดคงเหลือเบื้องต้น
    for (var wallet in _wallets) {
      _totalBalance += wallet.initialBalance;
    }

    // 2. คำนวณรายรับ-รายจ่าย จากประวัติธุรกรรมทั้งหมด
    for (var tx in _transactions) {
      bool isThisMonth = tx.dateTime.year == now.year && tx.dateTime.month == now.month;
      bool isToday = isThisMonth && tx.dateTime.day == now.day;

      if (tx.type == 'income') {
        _totalBalance += tx.amount; 
        if (isThisMonth) {
          _totalIncomeMonth += tx.amount;
        }
      } else if (tx.type == 'expense') {
        _totalBalance -= tx.amount; 

        if (isThisMonth) {
          _monthlyExpense += tx.amount;
        }
        if (isToday) {
          _dailyExpense += tx.amount;
        }
      }
    }
  }

  // ==========================================
  // ดึงยอดเงินคงเหลือของกระเป๋าแต่ละใบ
  // ==========================================
  double getWalletBalance(int walletId) {
    // หาเงินตั้งต้นของกระเป๋า
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId, 
      orElse: () => Wallet(id: 0, name: '', initialBalance: 0, emojiIcon: '')
    );
    double balance = wallet.initialBalance;

    // เอารายรับ-รายจ่ายของกระเป๋าใบนี้มาบวกลบ
    final walletTxs = _transactions.where((tx) => tx.walletId == walletId);
    for (var tx in walletTxs) {
      if (tx.type == 'income') {
        balance += tx.amount;
      } else if (tx.type == 'expense') {
        balance -= tx.amount;
      }
    }
    return balance;
  }
}