import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'main_layout.dart'; // เดี๋ยวเราจะสร้างไฟล์นี้ในขั้นตอนถัดไป

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  // ฟังก์ชันโหลดข้อมูลและเปลี่ยนหน้า
  Future<void> _loadDataAndNavigate() async {
    try {
      // ลองโหลดข้อมูล
      await Provider.of<FinanceProvider>(context, listen: false).loadData();
    } catch (e) {
      // ถ้าโหลดข้อมูลพลาด ให้พิมพ์ Error บอกเราแต่ยังยอมให้ไปหน้าถัดไปได้
      print("Error loading data: $e");
    }

    // หน่วงเวลา 2 วินาที
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // ⚠️ เอาคำว่า const หน้าวงเล็บ [ ออก เพื่อให้ใส่รูปภาพได้
          children: [
            // 🟢 เปลี่ยนจาก Icon มาเป็น Image.asset แทน
            Image.asset(
              'assets/images/loading.png', // ⚠️ เปลี่ยนโลโก้เป็นชื่อไฟล์ของคุณ (เช่น logo.jpg)
              width: 250,  // ปรับความกว้างของรูปตรงนี้ให้ใหญ่/เล็กได้ตามต้องการ
              height: 250, // ปรับความสูงให้สัมพันธ์กัน
              fit: BoxFit.contain, // จัดให้รูปพอดี ไม่เบี้ยว
            ),
            const SizedBox(height: 20),
            const Text(
              'LMA APP', // ชื่อแอปของคุณ
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // ไอคอนหมุนๆ แสดงการโหลด
          ],
        ),
      ),
    );
  }
}