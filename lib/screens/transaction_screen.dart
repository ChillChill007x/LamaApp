import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'ประวัติธุรกรรม', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // ใช้ Consumer เพื่อให้หน้านี้อัปเดตอัตโนมัติเมื่อมีการเพิ่ม/ลบ ข้อมูล
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;

          // ถ้ายังไม่มีข้อมูลให้โชว์ข้อความนี้
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีประวัติการทำธุรกรรม', 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
          }

          // ถ้ามีข้อมูล ให้สร้างเป็นรายการ (ListView)
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isIncome = tx.type == 'income';

              // Dismissible คือ Widget ที่ทำให้เรา "ปัดซ้ายเพื่อลบ" ได้
              return Dismissible(
                key: Key(tx.id.toString()),
                direction: DismissDirection.endToStart, // กำหนดให้ปัดจากขวาไปซ้าย
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                onDismissed: (direction) {
                  // สั่งลบข้อมูลออกจากฐานข้อมูล
                  provider.deleteTransaction(tx.id!);
                  
                  // แสดงแจ้งเตือนด้านล่าง
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบรายการ "${tx.category}" เรียบร้อย')),
                  );
                },
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      tx.category, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    // แสดงวันที่และเวลา (จัดรูปแบบเติม 0 ด้านหน้าถ้าเลขตัวเดียว)
                    subtitle: Text(
                      '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year} • ${tx.dateTime.hour}:${tx.dateTime.minute.toString().padLeft(2, '0')} น.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'} ฿${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}