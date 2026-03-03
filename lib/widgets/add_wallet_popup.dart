import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/wallet_model.dart';

class AddWalletPopup extends StatefulWidget {
  const AddWalletPopup({Key? key}) : super(key: key);

  @override
  State<AddWalletPopup> createState() => _AddWalletPopupState();
}

class _AddWalletPopupState extends State<AddWalletPopup> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedEmoji = '💰'; // ไอคอนเริ่มต้น

  // ฟังก์ชันบันทึกกระเป๋าตัง
  void _saveWallet() {
    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();

    // เช็คว่ากรอกข้อมูลครบไหม
    if (name.isEmpty || balanceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อกระเป๋าและเงินตั้งต้นให้ครบถ้วน')),
      );
      return;
    }

    final balance = double.tryParse(balanceText) ?? 0.0;

    // สร้าง Object กระเป๋าตังใหม่
    final newWallet = Wallet(
      name: name,
      emojiIcon: _selectedEmoji,
      initialBalance: balance,
      note: _noteController.text,
    );

    // ส่งให้ Provider บันทึกลง Database
    Provider.of<FinanceProvider>(context, listen: false).addWallet(newWallet);
    
    // ปิดป๊อปอัพ
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Padding เพื่อดัน UI ขึ้นเวลาคีย์บอร์ดมือถือเด้งขึ้นมา
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'เพิ่มกระเป๋าตัง',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // ปุ่มเลือกไอคอน (ทำแบบง่ายๆ เป็นปุ่มกดเปลี่ยนไปก่อน)
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade50,
            child: Text(_selectedEmoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 10),

          // ช่องกรอกชื่อกระเป๋า
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'ชื่อกระเป๋า (เช่น เงินสด, บัญชีธนาคาร)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // ช่องกรอกเงินตั้งต้น
          TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'ยอดเงินตั้งต้น (บาท)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // ช่องกรอกบันทึกช่วยจำ
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'บันทึกช่วยจำ (ไม่บังคับ)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          // ปุ่มยืนยัน
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('บันทึก', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}