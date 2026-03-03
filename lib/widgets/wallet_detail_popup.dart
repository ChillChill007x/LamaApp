import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

// 🟢 เปลี่ยนเป็น StatefulWidget เพื่อรองรับการพิมพ์และแก้ไขข้อความ
class WalletDetailPopup extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailPopup({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletDetailPopup> createState() => _WalletDetailPopupState();
}

class _WalletDetailPopupState extends State<WalletDetailPopup> {
  // ตัวแปรควบคุมช่องพิมพ์ข้อความ
  late TextEditingController _noteController;
  late FocusNode _noteFocus;

  @override
  void initState() {
    super.initState();
    // 💡 ดึงข้อความบันทึกช่วยจำเดิมมาแสดง (แก้ .note ให้ตรงกับชื่อตัวแปรใน Model ของคุณ)
    _noteController = TextEditingController(text: widget.wallet.note ?? '');
    _noteFocus = FocusNode();

    // 🟢 ระบบบันทึกอัตโนมัติ: เมื่อพิมพ์เสร็จและกดแตะที่อื่น (เสีย Focus) ให้อัปเดตข้อมูลทันที
    _noteFocus.addListener(() {
      if (!_noteFocus.hasFocus) {
        _saveNote();
      }
    });
  }

  // ฟังก์ชันบันทึกข้อความลง Database
  // ฟังก์ชันบันทึกข้อความลง Database
  void _saveNote() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    
    // 💡 สร้าง Object ใหม่โดยก๊อปปี้ค่าเดิม แต่เปลี่ยนเฉพาะ note
    final updatedWallet = widget.wallet.copyWith(
      note: _noteController.text,
    );
    
    // ส่ง Object ตัวที่อัปเดตแล้วไปที่ Provider
    finance.updateWallet(updatedWallet);
  }

  @override
  void dispose() {
    // ล้างหน่วยความจำเมื่อปิด Popup
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    double currentBalance = widget.wallet.id != null 
        ? finance.getWalletBalance(widget.wallet.id!) 
        : widget.wallet.initialBalance;

    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;
    DateTime now = DateTime.now();
    List<TransactionItem> walletTransactions = [];

    if (widget.wallet.id != null) {
      walletTransactions = finance.transactions.where((tx) => tx.walletId == widget.wallet.id).toList();
      walletTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      for (var tx in walletTransactions) {
        bool isThisMonth = tx.dateTime.year == now.year && tx.dateTime.month == now.month;
        if (isThisMonth) {
          if (tx.type == 'income') {
            monthlyIncome += tx.amount;
          } else if (tx.type == 'expense') {
            monthlyExpense += tx.amount;
          }
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รายละเอียด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirm(context, finance),
                  ),
                  InkWell(
                    onTap: () {
                      _noteFocus.unfocus(); // บังคับเซฟก่อนปิด (ถ้ากำลังพิมพ์อยู่)
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.wallet.emojiIcon.isNotEmpty ? widget.wallet.emojiIcon : '👛', 
                          style: const TextStyle(fontSize: 24)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(widget.wallet.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('ยอดคงเหลือ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(
                    '${currentBalance.toStringAsFixed(2)} บาท',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  const Text('รอบเดือน', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox('รายจ่าย', monthlyExpense, Colors.red.shade100, Colors.red),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInfoBox('รายรับ', monthlyIncome, Colors.lightGreen.shade200, Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionTitle('แนวโน้ม', '1 มี.ค - 31 มี.ค'),
                  _buildPlaceholderBox(height: 150),
                  const SizedBox(height: 20),

                  // 📝 5. บันทึกช่วยจำ (แก้ไขได้!)
                  _buildSectionTitle('บันทึกช่วยจำ', '(แตะเพื่อแก้ไข)'),
                  TextField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    maxLines: 3, // ให้พิมพ์ได้สูงสุด 3 บรรทัด
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'เพิ่มบันทึกช่วยจำ...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) {
                      // กด Enter หรือปุ่ม Done บนคีย์บอร์ด ก็เซฟเหมือนกัน
                      _noteFocus.unfocus();
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildSectionTitle('ธุรกรรม', ''),
                  _buildTransactionList(walletTransactions),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text('ยังไม่มีรายการธุรกรรม', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == 'income';

        return Card(
          elevation: 0,
          color: Colors.grey.shade50,
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
                fontSize: 14,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(String title, double amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            '${amount.toStringAsFixed(2)} บาท',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 10),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'โปรดรออัพเดทครับ ไม่ก็โอนให้ผม90ทรู', 
        style: TextStyle(
          color: Colors.grey, 
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบกระเป๋าตังค์?'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบกระเป๋า "${widget.wallet.name}" ข้อมูลธุรกรรมทั้งหมดในนี้จะหายไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (widget.wallet.id != null) {
                await finance.deleteWallet(widget.wallet.id!);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ลบกระเป๋า "${widget.wallet.name}" เรียบร้อยแล้ว')),
              );
            },
            child: const Text('ลบเลย', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}