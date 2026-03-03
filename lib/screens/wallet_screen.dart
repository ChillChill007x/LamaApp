import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'กระเป๋าตังของฉัน', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          final wallets = provider.wallets;

          if (wallets.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีกระเป๋าตัง\nกดปุ่ม + มุมขวาบนในหน้าภาพรวมเพื่อเพิ่ม', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];

              // 🟢 ระบบคำนวณยอดเงินปัจจุบันของกระเป๋าใบนี้ (ยอดตั้งต้น + รับ - จ่าย)
              double currentBalance = wallet.initialBalance;
              final walletTransactions = provider.transactions.where((tx) => tx.walletId == wallet.id);
              
              for (var tx in walletTransactions) {
                if (tx.type == 'income') {
                  currentBalance += tx.amount;
                } else if (tx.type == 'expense') {
                  currentBalance -= tx.amount;
                }
              }
 
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(wallet.emojiIcon, style: const TextStyle(fontSize: 30)),
                  ),
                  title: Text(
                    wallet.name, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    wallet.note?.isNotEmpty == true ? wallet.note! : 'ไม่มีบันทึกช่วยจำ', 
                    style: const TextStyle(color: Colors.grey)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🟢 เปลี่ยนมาโชว์ตัวแปร currentBalance ที่เราเพิ่งคำนวณเสร็จ
                      Text(
                        '฿${currentBalance.toStringAsFixed(2)}', 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          // ถ้าเงินติดลบ ให้โชว์สีแดง, ถ้าเป็นบวกโชว์สีฟ้า
                          color: currentBalance < 0 ? Colors.redAccent : Colors.blueAccent
                        )
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          _showDeleteConfirm(context, provider, wallet.id!, wallet.name);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, FinanceProvider provider, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ลบกระเป๋าตัง'),
        content: Text('คุณต้องการลบกระเป๋า "$name" ใช่หรือไม่?\n\n⚠️ คำเตือน: รายการธุรกรรมทั้งหมดที่เชื่อมกับกระเป๋านี้จะถูกลบไปด้วย!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.deleteWallet(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ลบกระเป๋าตังเรียบร้อยแล้ว')),
              );
            },
            child: const Text('ลบกระเป๋า', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}