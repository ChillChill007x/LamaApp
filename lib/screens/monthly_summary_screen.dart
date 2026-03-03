import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({Key? key}) : super(key: key);

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  // 🟢 สร้างตัวแปรเก็บเดือนและปีที่เลือก (ค่าเริ่มต้นคือเดือนและปีปัจจุบัน)
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // 🟢 รายชื่อเดือนสำหรับแสดงใน Dropdown (Index 0 คือ ทั้งปี)
  final List<String> _monthNames = [
    'ดูตลอดทั้งปี', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน',
    'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('สรุปรายการ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: '💸 รายจ่าย'),
              Tab(text: '💰 รายรับ'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ==========================================
            // 🟢 แถบเลือก เดือน และ ปี
            // ==========================================
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // เลือกเดือน
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          items: List.generate(13, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text(_monthNames[index], style: TextStyle(fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal)),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // เลือกปี
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          // สร้างตัวเลือกปีย้อนหลัง 5 ปี
                          items: List.generate(5, (index) {
                            int year = DateTime.now().year - index;
                            return DropdownMenuItem(value: year, child: Text(year.toString()));
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // ส่วนแสดงผลเนื้อหา (TabBarView)
            // ==========================================
            Expanded(
              child: Consumer<FinanceProvider>(
                builder: (context, provider, child) {
                  // 🟢 1. กรองข้อมูลตาม เดือน/ปี ที่ผู้ใช้เลือก
                  final filteredTransactions = provider.transactions.where((tx) {
                    bool matchYear = tx.dateTime.year == _selectedYear;
                    // ถ้า _selectedMonth เป็น 0 คือให้โชว์ทั้งหมด ไม่ต้องกรองเดือน
                    bool matchMonth = _selectedMonth == 0 ? true : tx.dateTime.month == _selectedMonth;
                    return matchYear && matchMonth;
                  }).toList();

                  // 🟢 2. แยกรายจ่าย และคำนวณยอดรวมใหม่
                  final expenses = filteredTransactions.where((tx) => tx.type == 'expense').toList();
                  double totalExpense = 0;
                  Map<String, double> expenseTotals = {};
                  for (var tx in expenses) {
                    totalExpense += tx.amount;
                    expenseTotals[tx.category] = (expenseTotals[tx.category] ?? 0) + tx.amount;
                  }
                  var sortedExpenses = expenseTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                  // 🟢 3. แยกรายรับ และคำนวณยอดรวมใหม่
                  final incomes = filteredTransactions.where((tx) => tx.type == 'income').toList();
                  double totalIncome = 0;
                  Map<String, double> incomeTotals = {};
                  for (var tx in incomes) {
                    totalIncome += tx.amount;
                    incomeTotals[tx.category] = (incomeTotals[tx.category] ?? 0) + tx.amount;
                  }
                  var sortedIncomes = incomeTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                  return TabBarView(
                    children: [
                      // หน้าที่ 1: รายจ่าย
                      _buildSummaryTab(
                        title: _selectedMonth == 0 ? 'รายจ่ายรวมปี $_selectedYear' : 'รายจ่ายรวมเดือนนี้',
                        totalAmount: totalExpense, // ใช้ค่ายอดรวมที่เพิ่งคำนวณ
                        categories: sortedExpenses,
                        themeColor: Colors.redAccent,
                        icon: Icons.receipt_long,
                        prefix: '-',
                      ),
                      // หน้าที่ 2: รายรับ
                      _buildSummaryTab(
                        title: _selectedMonth == 0 ? 'รายรับรวมปี $_selectedYear' : 'รายรับรวมเดือนนี้',
                        totalAmount: totalIncome, // ใช้ค่ายอดรวมที่เพิ่งคำนวณ
                        categories: sortedIncomes,
                        themeColor: Colors.green,
                        icon: Icons.account_balance_wallet,
                        prefix: '+',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันวาดหน้าจอสรุป (คงไว้เหมือนเดิม)
  Widget _buildSummaryTab({
    required String title,
    required double totalAmount,
    required List<MapEntry<String, double>> categories,
    required Color themeColor,
    required IconData icon,
    required String prefix,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ]
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '฿${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('แยกตามหมวดหมู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: categories.isEmpty
              ? Center(child: Text('ไม่มีข้อมูลในช่วงเวลานี้', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index].key;
                    final amount = categories[index].value;
                    final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeColor.withOpacity(0.15),
                          child: Icon(icon, color: themeColor),
                        ),
                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('คิดเป็น ${percentage.toStringAsFixed(1)}% ของทั้งหมด'),
                        trailing: Text(
                          '$prefix ฿${amount.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}