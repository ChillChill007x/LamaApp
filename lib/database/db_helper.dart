import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class DBHelper {
  // สร้าง Singleton Pattern เพื่อให้เรียกใช้ Database ได้จากทุกที่โดยไม่ต้องสร้างใหม่หลายรอบ
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  // ฟังก์ชันสำหรับเรียกใช้งาน Database (ถ้ายังไม่มีจะทำการสร้างใหม่)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // กำหนดตำแหน่งที่เก็บไฟล์ฐานข้อมูล และเวอร์ชัน
  // แก้ไขฟังก์ชัน _initDatabase เพิ่มเติม
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // ➕ เพิ่มบรรทัดนี้เพื่อเปิดระบบ Foreign Key (Cascade Delete)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // สร้างตารางข้อมูลเมื่อเปิดแอปครั้งแรก
  Future _onCreate(Database db, int version) async {
    // 1. ตารางกระเป๋าตัง (wallets)
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emojiIcon TEXT NOT NULL,
        initialBalance REAL NOT NULL,
        note TEXT
      )
    ''');

    // 2. ตารางธุรกรรม (transactions)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        walletId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // ส่วนจัดการข้อมูล Wallet (กระเป๋าตัง)
  // ==========================================

  // เพิ่มกระเป๋าตังใหม่
  Future<int> insertWallet(Wallet wallet) async {
    Database db = await database;
    return await db.insert('wallets', wallet.toMap());
  }

  // ดึงข้อมูลกระเป๋าตังทั้งหมด
  Future<List<Wallet>> getWallets() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('wallets');
    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  // ลบกระเป๋าตัง
  Future<int> deleteWallet(int id) async {
    Database db = await database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }
  // อัปเดตข้อมูลกระเป๋าตัง (ใช้สำหรับแก้ไขชื่อ, ไอคอน หรือบันทึกช่วยจำ)
  Future<int> updateWallet(Wallet wallet) async {
    Database db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  // ==========================================
  // ส่วนจัดการข้อมูล Transaction (รายการธุรกรรม)
  // ==========================================

  // เพิ่มรายการธุรกรรมใหม่
  Future<int> insertTransaction(TransactionItem transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // ดึงรายการธุรกรรมทั้งหมด เรียงจากใหม่ไปเก่า
  Future<List<TransactionItem>> getTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  // ดึงรายการธุรกรรมเฉพาะของกระเป๋าตังใบใดใบหนึ่ง
  Future<List<TransactionItem>> getTransactionsByWalletId(int walletId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'walletId = ?',
      whereArgs: [walletId],
      orderBy: 'dateTime DESC'
    );
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  // ลบรายการธุรกรรม
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}