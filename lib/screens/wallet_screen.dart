import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text(
          'ตารางงาน', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // ให้ปุ่ม Back เป็นสีดำ
      ),
      body: const SizedBox.expand(
        child: Center(
          child: Text(
            'รออัพเดท หรือไม่ก็โอนมาให้ผม90ทรู', 
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}