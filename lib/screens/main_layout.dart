import 'package:flutter/material.dart';
import 'overview_screen.dart';
import 'transaction_screen.dart';
import 'wallet_screen.dart';
import '../widgets/quick_menu_popup.dart';
import 'monthly_summary_screen.dart'; 

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // รายการหน้าจอที่จะสลับไปมา (เรียงตาม Index 0, 1, 2)
  final List<Widget> _pages = [
    const OverviewScreen(),
    const TransactionScreen(),
    const WalletScreen(),
    const MonthlySummaryScreen(),
  ];

  // ฟังก์ชันเมื่อผู้ใช้กดเมนูด้านล่าง
  void _onItemTapped(int index) {
    if (index == 2) {
      // ถ้ากดปุ่มตำแหน่งที่ 3 (เมนูตรงกลาง) โชว์ Popup
      _showQuickMenu();
    } else {
      // สลับหน้าจอ
      setState(() {
        _selectedIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  // ฟังก์ชันแสดงป๊อปอัพ Quick Menu
  void _showQuickMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => const QuickMenuPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      
      // --- ส่วนของแถบเมนูด้านล่างที่ปรับปรุงใหม่ ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(247,239,96,1.000), //  แก้สีพื้นหลังหลักของแถบเมนูที่นี่
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // ใส่เงาจางๆ ให้ดูมีมิติ
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          // ถ้าอยากให้ขอบด้านบนโค้งมน สามารถเปิดใช้งานบรรทัดข้างล่างนี้ได้ครับ
          // borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromRGBO(159,235,249,1.000), // 🟢 ใส่สีเดียวกับ Container
          elevation: 0, // ปิดเงาเดิมของเครื่องเพื่อใช้เงาจาก Container แทน
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color.fromRGBO(247,239,96,1.000), // สีไอคอนที่เลือก
          unselectedItemColor: const Color.fromARGB(255, 0, 0, 0), // สีไอคอนที่ไม่ได้เลือก
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'ภาพรวม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'ธุรกรรม',
          ),
          BottomNavigationBarItem(
            // ปุ่มเมนูด่วน ทำให้ดูโดดเด่นขึ้น
            icon: Icon(Icons.add_circle, size: 60, color: Color.fromRGBO(247,239,96,1.000)),
            label: 'เมนู',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'ตารางงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_sharp),
            label: 'สรุป',
          ),
          ],
        ),
      ),
    );
  }
}