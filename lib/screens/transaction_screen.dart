import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../providers/user_provider.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ── ประวัติ tab state ──
  int? _selectedWalletId;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── สรุป tab state ──
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;
  int _summaryWalletId = 0; // 0 = ทุกกระเป๋า

  static const _monthNames = [
    'ทั้งปี','ม.ค.','ก.พ.','มี.ค.','เม.ย.','พ.ค.','มิ.ย.',
    'ก.ค.','ส.ค.','ก.ย.','ต.ค.','พ.ย.','ธ.ค.',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('ธุรกรรม',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            bottom: TabBar(
              controller: _tab,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: const [
                Tab(text: '📋 ประวัติ'),
                Tab(text: '💸 รายจ่าย'),
                Tab(text: '💰 รายรับ'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _buildHistoryTab(provider),
              _buildSummaryTab(provider, type: 'expense'),
              _buildSummaryTab(provider, type: 'income'),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  // Tab 1: ประวัติธุรกรรม
  // ════════════════════════════════════════════════════
  Widget _buildHistoryTab(FinanceProvider provider) {
    List<TransactionItem> filtered = provider.transactions;
    if (_selectedWalletId != null) {
      filtered = filtered.where((tx) => tx.walletId == _selectedWalletId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) =>
          tx.category.toLowerCase().contains(q) ||
          tx.amount.toString().contains(q) ||
          (tx.note?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildWalletFilterBar(provider.wallets),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(_searchQuery.isNotEmpty
                  ? 'ไม่พบรายการที่ค้นหา'
                  : 'ยังไม่มีรายการ')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildTxCard(filtered[i], provider),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'ค้นหา หมวดหมู่ หรือ จำนวนเงิน...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  })
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildWalletFilterBar(List<Wallet> wallets) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          _filterChip('ทั้งหมด', '📋', _selectedWalletId == null,
              () => setState(() => _selectedWalletId = null)),
          ...wallets.map((w) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _filterChip(
              w.name, w.emojiIcon.isNotEmpty ? w.emojiIcon : '👛',
              _selectedWalletId == w.id,
              () => setState(() => _selectedWalletId = w.id),
            ),
          )),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String emoji, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.blueAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? Colors.blueAccent : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : Colors.black87)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // Chart helpers
  // ════════════════════════════════════════════════════

  // สีสำหรับ pie slices
  static const List<Color> _chartColors = [
    Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
    Color(0xFFFF7043), Color(0xFF66BB6A), Color(0xFFAB47BC),
    Color(0xFF29B6F6), Color(0xFFFFCA28), Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  Widget _buildPieChart(List<MapEntry<String, double>> sorted,
      double total, Color themeColor) {
    final top5 = sorted.take(5).toList();
    final otherAmt = sorted.skip(5).fold(0.0, (s, e) => s + e.value);
    final items = [...top5, if (otherAmt > 0) MapEntry('อื่นๆ', otherAmt)];

    int _touchedIdx = -1;

    return StatefulBuilder(builder: (ctx, setSS) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100,
              blurRadius: 8, spreadRadius: 2)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('สัดส่วนหมวดหมู่',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            // Pie
            SizedBox(
              width: 150, height: 150,
              child: PieChart(PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (ev, resp) {
                    setSS(() {
                      if (resp?.touchedSection != null) {
                        _touchedIdx = resp!.touchedSection!.touchedSectionIndex;
                      } else {
                        _touchedIdx = -1;
                      }
                    });
                  },
                ),
                sections: items.asMap().entries.map((e) {
                  final idx    = e.key;
                  final entry  = e.value;
                  final pct    = entry.value / total * 100;
                  final isTouched = idx == _touchedIdx;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: TextStyle(
                        fontSize: isTouched ? 13 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: isTouched ? 64 : 54,
                    color: _chartColors[idx % _chartColors.length],
                  );
                }).toList(),
                centerSpaceRadius: 28,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            // Legend
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.asMap().entries.map((e) {
                final idx   = e.key;
                final entry = e.value;
                final pct   = entry.value / total * 100;
                // ตัดชื่อหมวดให้สั้น
                String label = entry.key;
                if (label.length > 10) label = '${label.substring(0, 9)}…';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[idx % _chartColors.length],
                          borderRadius: BorderRadius.circular(3),
                        )),
                    const SizedBox(width: 6),
                    Expanded(child: Text(label,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis)),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11,
                            color: Colors.grey.shade600)),
                  ]),
                );
              }).toList(),
            )),
          ]),
        ]),
      );
    });
  }

  Widget _buildBarChart(List<TransactionItem> filtered, Color themeColor) {
    // รายวันในเดือน
    final Map<int, double> dayMap = {};
    for (final tx in filtered) {
      dayMap[tx.dateTime.day] = (dayMap[tx.dateTime.day] ?? 0) + tx.amount;
    }
    if (dayMap.isEmpty) return const SizedBox.shrink();

    final maxVal = dayMap.values.reduce(math.max);
    final days   = List.generate(
        DateUtils.getDaysInMonth(_selectedYear, _selectedMonth), (i) => i + 1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade100,
            blurRadius: 8, spreadRadius: 2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('รายจ่ายรายวัน',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: BarChart(BarChartData(
            maxY: maxVal * 1.25,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  'วัน ${group.x}\n฿${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (val, _) {
                    final day = val.toInt();
                    if (day % 5 != 0) return const SizedBox.shrink();
                    return Text('$day',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500));
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxVal / 3,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.grey.shade100, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: days.map((day) {
              final amt = dayMap[day] ?? 0;
              return BarChartGroupData(x: day, barRods: [
                BarChartRodData(
                  toY: amt,
                  color: amt > 0
                      ? themeColor.withOpacity(amt == maxVal ? 1.0 : 0.6)
                      : Colors.grey.shade100,
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ]);
            }).toList(),
          )),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'วันที่ใช้จ่ายสูงสุด: วันที่ ${dayMap.entries.reduce((a, b) => a.value > b.value ? a : b).key}  ฿${maxVal.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ]),
    );
  }

  Widget _buildTxCard(TransactionItem tx, FinanceProvider provider) {
    final isIncome = tx.type == 'income';
    final wallet = provider.wallets.firstWhere(
      (w) => w.id == tx.walletId,
      orElse: () => Wallet(id: 0, name: 'ไม่ทราบ', emojiIcon: '👛', initialBalance: 0),
    );
    final hasSlip = tx.imagePath != null && tx.imagePath!.isNotEmpty;

    // ── แสดง emoji + ชื่อหมวดหมู่ ─────────────────────
    // รายการใหม่จะมี emoji อยู่แล้ว (เช่น "🍜 อาหาร")
    // รายการเก่า → ค้นหา emoji จาก UserProvider
    final userProv = Provider.of<UserProvider>(context, listen: false);
    String displayCategory = tx.category;
    if (!tx.category.contains(' ') || tx.category.runes.first < 0x1F000) {
      // ชื่อยังไม่มี emoji → ค้นหาจาก UserProvider
      final allCats = [...userProv.expenseCategories, ...userProv.incomeCategories];
      final match = allCats.firstWhere(
        (c) => c.name == tx.category.trim(),
        orElse: () => allCats.firstWhere(
          (c) => tx.category.contains(c.name),
          orElse: () => allCats.first,
        ),
      );
      // ถ้าเจอ และ category ยังไม่มี emoji นำหน้า
      if (!tx.category.startsWith(match.emoji)) {
        displayCategory = '${match.emoji} ${tx.category}';
      }
    }

    return Dismissible(
      key: Key('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ลบรายการ?'),
          content: Text('ต้องการลบ "${tx.category}" ใช่ไหม?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ลบ', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
      onDismissed: (_) {
        provider.deleteTransaction(tx.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบ "${tx.category}" เรียบร้อย')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.red.shade400, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete, color: Colors.white, size: 26),
      ),
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showEditTxSheet(context, tx, provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              if (hasSlip)
                GestureDetector(
                  onTap: () => _showSlipViewer(context, tx.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(tx.imagePath!),
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _txIcon(isIncome)),
                  ),
                )
              else
                _txIcon(isIncome),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // ✅ แสดง emoji + ชื่อหมวดหมู่
                      Expanded(child: Text(displayCategory,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      if (hasSlip)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('📎 สลิป',
                              style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}  '
                      '${tx.dateTime.hour}:${tx.dateTime.minute.toString().padLeft(2, '0')} น.',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    if (_selectedWalletId == null) ...[
                      const SizedBox(height: 4),
                      _walletBadge(wallet, isIncome),
                    ],
                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(tx.note!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  '${isIncome ? '+' : '-'} ฿${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                      color: isIncome ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 4),
                Text('แตะแก้ไข',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _txIcon(bool isIncome) => CircleAvatar(
    radius: 22,
    backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
    child: Icon(
      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
      color: isIncome ? Colors.green : Colors.red, size: 18,
    ),
  );

  Widget _walletBadge(Wallet wallet, bool isIncome) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: isIncome ? Colors.green.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: isIncome ? Colors.green.shade200 : Colors.grey.shade300, width: 0.8),
    ),
    child: Text('${wallet.emojiIcon} ${wallet.name}',
        style: TextStyle(fontSize: 11,
            color: isIncome ? Colors.green.shade700 : Colors.grey.shade700,
            fontWeight: FontWeight.w500)),
  );

  // ════════════════════════════════════════════════════
  // Tab 2 & 3: สรุปรายจ่าย / รายรับ (จาก monthly_summary_screen)
  // ════════════════════════════════════════════════════
  Widget _buildSummaryTab(FinanceProvider provider, {required String type}) {
    final isExpense   = type == 'expense';
    final themeColor  = isExpense ? Colors.redAccent : Colors.green;
    final icon        = isExpense ? Icons.receipt_long : Icons.account_balance_wallet;
    final prefix      = isExpense ? '-' : '+';

    // กรองตามเดือน/ปี/กระเป๋า
    final filtered = provider.transactions.where((tx) {
      final matchYear   = tx.dateTime.year == _selectedYear;
      final matchMonth  = _selectedMonth == 0 ? true : tx.dateTime.month == _selectedMonth;
      final matchWallet = _summaryWalletId == 0 ? true : tx.walletId == _summaryWalletId;
      return tx.type == type && matchYear && matchMonth && matchWallet;
    }).toList();

    double total = 0;
    final Map<String, double> catMap = {};
    for (final tx in filtered) {
      total += tx.amount;
      catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
    }
    final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final title = _selectedMonth == 0
        ? '${isExpense ? 'รายจ่าย' : 'รายรับ'}รวมปี $_selectedYear'
        : '${isExpense ? 'รายจ่าย' : 'รายรับ'} ${_monthNames[_selectedMonth]} $_selectedYear';

    return Column(
      children: [
        // ── Filter bar (คงที่ด้านบน) ───────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(children: [
            Row(children: [
              Expanded(flex: 2, child: _dropdownWrapper(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  items: List.generate(13, (i) => DropdownMenuItem(
                    value: i,
                    child: Text(_monthNames[i], style: const TextStyle(fontSize: 13)),
                  )),
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: _dropdownWrapper(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  items: List.generate(5, (i) {
                    final y = DateTime.now().year - i;
                    return DropdownMenuItem(value: y,
                        child: Text('$y', style: const TextStyle(fontSize: 13)));
                  }),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
              )),
            ]),
            const SizedBox(height: 8),
            _dropdownWrapper(
              child: DropdownButton<int>(
                value: _summaryWalletId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('👛 ทุกกระเป๋า',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ...provider.wallets.map((w) => DropdownMenuItem(
                    value: w.id,
                    child: Text('${w.emojiIcon} ${w.name}',
                        style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) => setState(() => _summaryWalletId = v!),
              ),
            ),
          ]),
        ),

        // ── เนื้อหาทั้งหมด scroll ได้ ──────────────────
        Expanded(
          child: sorted.isEmpty
              ? _emptyState('ไม่มีข้อมูลในช่วงเวลานี้')
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    // ยอดรวม
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(children: [
                        Text(title,
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('฿${total.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 30,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),

                    // Pie Chart
                    _buildPieChart(sorted, total, themeColor),

                    // Bar Chart รายวัน (เฉพาะตอนเลือกเดือน)
                    if (_selectedMonth != 0)
                      _buildBarChart(filtered, themeColor),

                    // หัว แยกตามหมวดหมู่
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('แยกตามหมวดหมู่',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // รายการหมวดหมู่
                    ...sorted.asMap().entries.map((e) {
                      final cat = e.value.key;
                      final amt = e.value.value;
                      final pct = total > 0 ? (amt / total * 100) : 0.0;
                      final rank = e.key;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.grey.shade100,
                              blurRadius: 4, spreadRadius: 1)],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _chartColors[rank % _chartColors.length]
                                .withOpacity(0.15),
                            child: Text(
                              cat.contains(' ') ? cat.split(' ').first : '💰',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(cat,
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _chartColors[rank % _chartColors.length]),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text('${pct.toStringAsFixed(1)}% ของทั้งหมด',
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          trailing: Text('$prefix ฿${amt.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                  color: themeColor, fontSize: 14)),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _dropdownWrapper({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: DropdownButtonHideUnderline(child: child),
  );

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    ),
  );

  // ════════════════════════════════════════════════════
  // Slip viewer
  // ════════════════════════════════════════════════════
  void _showSlipViewer(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(children: [
          InteractiveViewer(child: Image.file(File(imagePath), fit: BoxFit.contain)),
          Positioned(
            top: 8, right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // Edit Transaction Sheet
  // ════════════════════════════════════════════════════
  void _showEditTxSheet(BuildContext context, TransactionItem tx, FinanceProvider provider) {
    final amountCtrl = TextEditingController(text: tx.amount.toStringAsFixed(0));
    final noteCtrl   = TextEditingController(text: tx.note ?? '');
    bool isIncome           = tx.type == 'income';
    String selectedCategory = tx.category;
    int? selectedWalletId   = tx.walletId;
    DateTime selectedDate   = tx.dateTime;
    String? imagePath       = tx.imagePath;

    final expenseCats = ['อาหาร','ขนม','เดินทาง','ช้อปปิ้ง','บันเทิง','ค่าน้ำมัน','เครื่องสำอาง','เติมเกม','อื่นๆ'];
    final incomeCats  = ['เงินเดือน','ธุรกิจ','โบนัส','อื่นๆ'];
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSS) {
          final cats = isIncome ? incomeCats : expenseCats;
          if (!cats.contains(selectedCategory)) selectedCategory = cats.first;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('แก้ไขรายการ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isIncome ? Colors.redAccent : Colors.grey.shade200,
                        foregroundColor: !isIncome ? Colors.white : Colors.black54, elevation: 0),
                      onPressed: () => setSS(() => isIncome = false),
                      child: const Text('รายจ่าย'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? Colors.green : Colors.grey.shade200,
                        foregroundColor: isIncome ? Colors.white : Colors.black54, elevation: 0),
                      onPressed: () => setSS(() => isIncome = true),
                      child: const Text('รายรับ'),
                    )),
                  ]),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixText: '฿ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('หมวดหมู่',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: cats.map((cat) {
                    final sel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                      onSelected: (_) => setSS(() => selectedCategory = cat),
                    );
                  }).toList()),
                  const SizedBox(height: 12),

                  if (provider.wallets.isNotEmpty) ...[
                    const Text('กระเป๋า',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedWalletId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: provider.wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.emojiIcon} ${w.name}'),
                      )).toList(),
                      onChanged: (v) => setSS(() => selectedWalletId = v),
                    ),
                    const SizedBox(height: 12),
                  ],

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020), lastDate: DateTime(2100),
                      );
                      if (picked != null) setSS(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'หมายเหตุ (ไม่บังคับ)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('แนบสลิป / รูปภาพ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('ถ่ายรูป', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final xFile = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (xFile != null) setSS(() => imagePath = xFile.path);
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('จากคลัง', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final xFile = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 70);
                        if (xFile != null) setSS(() => imagePath = xFile.path);
                      },
                    )),
                  ]),
                  if (imagePath != null && imagePath!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(imagePath!),
                            height: 120, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 60, color: Colors.grey.shade100,
                              child: const Center(child: Text('ไม่สามารถโหลดรูปได้')),
                            )),
                      ),
                      Positioned(top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => setSS(() => imagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0 || selectedWalletId == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
                          return;
                        }
                        final updated = tx.copyWith(
                          walletId: selectedWalletId,
                          type: isIncome ? 'income' : 'expense',
                          amount: amount,
                          category: selectedCategory,
                          dateTime: selectedDate,
                          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                          imagePath: imagePath,
                          clearImage: imagePath == null,
                        );
                        await provider.updateTransaction(updated);
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('แก้ไขรายการเรียบร้อย')));
                      },
                      child: const Text('บันทึกการแก้ไข',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
