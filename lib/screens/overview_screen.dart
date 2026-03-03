import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/add_wallet_popup.dart';
import '../widgets/custom_calendar.dart';
import '../widgets/wallet_detail_popup.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'User Name', // อนาคตสามารถเปลี่ยนเป็นดึงจากฐานข้อมูลผู้ใช้ได้
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            // 
            /*actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 30),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => AddWalletPopup(),
                  );
                },
              ),
            ],*/
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // 🌟 1. ส่วนแถบกระเป๋าตังค์แนวนอน (ใหม่ล่าสุด!)
                _buildWalletList(context, finance),
                const SizedBox(height: 20),

                // นำ Padding มาคลุมเฉพาะส่วนเนื้อหาด้านล่าง เพื่อให้กระเป๋าตังค์เลื่อนสุดขอบจอได้
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. ส่วนสรุปยอดเงิน 4 ช่อง
                      _buildSummaryCards(finance),
                      const SizedBox(height: 20),

                      // 3. ส่วนของปฏิทิน
                      const CustomCalendar(),
                      const SizedBox(height: 20),

                      // 4. ส่วนรายการธุรกรรมล่าสุด
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildRecentTransactions(finance.transactions),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌟 Widget สร้างแถบกระเป๋าตังค์แนวนอน
  // 🌟 Widget สร้างแถบกระเป๋าตังค์แนวนอน
  // 🌟 Widget สร้างแถบกระเป๋าตังค์แนวนอน (ดึงข้อมูลจริงจาก Provider)
  Widget _buildWalletList(BuildContext context, FinanceProvider finance) {
    // ดึง List กระเป๋าทั้งหมดมาจาก Provider
    final wallets = finance.wallets; 

    return SizedBox(
      height: 55, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // จำนวนกล่อง = จำนวนกระเป๋าที่มี + 1 (ปุ่มเพิ่มกระเป๋า)
        itemCount: wallets.length + 1, 
        itemBuilder: (context, index) {
          
          // 🟢 กล่องสุดท้าย: ปุ่มเพิ่มกระเป๋า (+)
          if (index == wallets.length) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => AddWalletPopup(),
                );
              },
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.blueGrey, size: 28),
                ),
              ),
            );
          }

          // 🟢 กล่องกระเป๋าตังค์: ดึงข้อมูลทีละใบมาแสดง
          final wallet = wallets[index];
          
          // ใช้ฟังก์ชัน getWalletBalance ที่คุณเขียนไว้เพื่อคำนวณยอดเงินของกระเป๋านี้
          // (เช็ค null เซฟตี้ไว้เผื่อ id ยังไม่มี)
          double currentBalance = wallet.id != null 
              ? finance.getWalletBalance(wallet.id!) 
              : wallet.initialBalance;

          return GestureDetector( 
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WalletDetailPopup(wallet: wallet), 
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  // โชว์ Emoji ของกระเป๋า ถ้าไม่มีให้โชว์ 👛 เป็นค่าเริ่มต้น
                  Text(
                    wallet.emojiIcon.isNotEmpty ? wallet.emojiIcon : '👛', 
                    style: const TextStyle(fontSize: 22)
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name, // ดึงชื่อกระเป๋า
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${currentBalance.toStringAsFixed(2)} บาท', // ดึงยอดเงินคงเหลือ
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget สร้างกล่องสรุปยอดเงิน 4 ช่อง (เหมือนเดิม)
  Widget _buildSummaryCards(FinanceProvider finance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard('รอบเดือน', finance.monthlyExpense, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard('รายวัน', finance.dailyExpense, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCard('รายรับรวม', finance.totalIncomeMonth, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard('คงเหลือ', finance.totalBalance, Colors.blueAccent)),
          ],
        ),
      ],
    );
  }

  // Widget กล่องสี่เหลี่ยมย่อย (เหมือนเดิม)
  Widget _buildCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 5, spreadRadius: 1)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '฿${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // Widget แสดงรายการธุรกรรมล่าสุด (เหมือนเดิม)
  Widget _buildRecentTransactions(List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('ยังไม่มีรายการธุรกรรม', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    int itemCount = transactions.length > 5 ? 5 : transactions.length;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == 'income';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'} ฿${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}