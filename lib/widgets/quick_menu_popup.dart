import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';

class QuickMenuPopup extends StatefulWidget {
  const QuickMenuPopup({Key? key}) : super(key: key);

  @override
  State<QuickMenuPopup> createState() => _QuickMenuPopupState();
}

class _QuickMenuPopupState extends State<QuickMenuPopup> {
  bool _isIncome = false; 
  int? _selectedWalletId; // ✅ แก้ไข: เก็บแค่ ID แทน Object เพื่อแก้บัค Dropdown
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now(); 
  String _selectedCategory = 'อาหาร';

  final List<String> _expenseCategories = ['อาหาร', 'ขนม','เดินทาง', 'ช้อปปิ้ง', 'บันเทิง', 'ค่าน้ำมัน','เครื่องสำอาง', 'เติมเกม','อื่นๆ'];
  final List<String> _incomeCategories = ['เงินเดือน', 'ธุรกิจ', 'โบนัส', 'อื่นๆ'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      if (provider.wallets.isNotEmpty) {
        setState(() {
          _selectedWalletId = provider.wallets.first.id; // ✅ ตั้งค่าเริ่มต้นเป็น ID ของกระเป๋าใบแรก
        });
      }
    });
  }

  void _saveTransaction() {
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาสร้างกระเป๋าตังก่อนครับ!')));
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุจำนวนเงิน')));
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('จำนวนเงินต้องมากกว่า 0')));
      return;
    }

    final transaction = TransactionItem(
      walletId: _selectedWalletId!, // ✅ ใช้ ID ไปบันทึกลง Database ได้เลย
      type: _isIncome ? 'income' : 'expense',
      amount: amount,
      category: _selectedCategory,
      dateTime: _selectedDate,
    );

    Provider.of<FinanceProvider>(context, listen: false).addTransaction(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final wallets = provider.wallets;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    // ✅ ป้องกันบัค Dropdown: เช็คว่า ID ที่เลือกไว้ ยังมีอยู่ใน List กระเป๋าตังจริงๆ ไหม
    if (wallets.isNotEmpty) {
      bool idExists = wallets.any((w) => w.id == _selectedWalletId);
      if (!idExists) {
        _selectedWalletId = wallets.first.id; // ถ้าหาไม่เจอ ให้เด้งกลับไปเลือกใบแรกสุด
      }
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, 
        left: 20, right: 20, top: 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('บันทึกรายการ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // ✅ 1. Dropdown เลือกกระเป๋าตัง (แก้ไขให้ใช้ value เป็น ID)
            if (wallets.isEmpty)
              const Text('⚠️ กรุณาสร้างกระเป๋าตังก่อนบันทึกรายการ', style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<int>(
                value: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: 'เลือกกระเป๋าตัง',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: wallets.map((w) {
                // 💡 คำนวณยอดเงินปัจจุบันของกระเป๋าใบนี้
                final currentBalance = provider.getWalletBalance(w.id!); 
      
                return DropdownMenuItem<int>(
                  value: w.id,
                  child: Text(
                    '${w.emojiIcon} ${w.name} (คงเหลือ: ฿${currentBalance.toStringAsFixed(2)})', // 👈 เปลี่ยนจาก initialBalance เป็น currentBalance
                  ),
                );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
            const SizedBox(height: 15),

            // 2. เลือกประเภท (รายจ่าย / รายรับ)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isIncome ? Colors.redAccent : Colors.grey.shade200,
                      foregroundColor: !_isIncome ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isIncome = false),
                    child: const Text('รายจ่าย'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isIncome ? Colors.green : Colors.grey.shade200,
                      foregroundColor: _isIncome ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isIncome = true),
                    child: const Text('รายรับ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 3. กรอกจำนวนเงิน
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '฿ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            // 4. เลือกหมวดหมู่
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('หมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: _isIncome ? Colors.green.shade100 : Colors.red.shade100,
                  onSelected: (bool selected) {
                    setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 15),

            // 5. เลือกวันที่ 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('วันที่: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  child: const Text('เปลี่ยนวันที่'),
                )
              ],
            ),
            const SizedBox(height: 10),

            // 6. ปุ่มยืนยัน
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveTransaction,
                child: const Text('ยืนยัน', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}