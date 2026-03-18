import 'package:flutter/material.dart';
import 'overview_screen.dart';
import 'transaction_screen.dart';
import 'savings_screen.dart';
import 'work_screen.dart';
import '../widgets/quick_menu_popup.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 0=ภาพรวม, 1=ธุรกรรม, 2=ออมเงิน, 3=งาน
  final List<Widget> _pages = [
    const OverviewScreen(),
    const TransactionScreen(),
    const SavingsScreen(),
    const WalletScreen(),   // work_screen.dart → class WalletScreen
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined,          Icons.dashboard,              'ภาพรวม'),
    _NavItem(Icons.list_alt_outlined,           Icons.list_alt,               'ธุรกรรม'),
    _NavItem(Icons.savings_outlined,            Icons.savings,                'ออมเงิน'),
    _NavItem(Icons.calendar_month_outlined,     Icons.calendar_month,         'งาน'),
  ];

  void _showQuickMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickMenuPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navBg   = Color.fromRGBO(159, 235, 249, 1.0);
    const fabColor = Color.fromRGBO(247, 239, 96, 1.0);

    return Scaffold(
      body: _pages[_selectedIndex],

      // ── FAB กลาง ─────────────────────────────────────
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: _showQuickMenu,
          backgroundColor: fabColor,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 34, color: Colors.black87),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom bar ────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        color: navBg,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBtn(0),
            _buildNavBtn(1),
            const SizedBox(width: 72),
            _buildNavBtn(2),
            _buildNavBtn(3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBtn(int index) {
    final item     = _navItems[index];
    final isActive = _selectedIndex == index;
    const activeColor = Color.fromRGBO(247, 239, 96, 1.0);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? activeColor : Colors.black54,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
