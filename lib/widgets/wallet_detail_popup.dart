import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/recurring_rule_model.dart';

class WalletDetailPopup extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailPopup({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletDetailPopup> createState() => _WalletDetailPopupState();
}

class _WalletDetailPopupState extends State<WalletDetailPopup> {
  late TextEditingController _noteController;
  late FocusNode _noteFocus;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: widget.wallet.note ?? '');
    _noteFocus = FocusNode();
    _noteFocus.addListener(() {
      if (!_noteFocus.hasFocus) _saveNote();
    });
  }

  void _saveNote() {
    final finance =
        Provider.of<FinanceProvider>(context, listen: false);
    finance.updateWallet(
        widget.wallet.copyWith(note: _noteController.text));
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    // ดึง wallet ล่าสุดจาก provider (เพื่อให้ budget อัปเดตแบบ real-time)
    final wallet = finance.wallets.firstWhere(
      (w) => w.id == widget.wallet.id,
      orElse: () => widget.wallet,
    );

    final currentBalance = wallet.id != null
        ? finance.getWalletBalance(wallet.id!)
        : wallet.initialBalance;

    final now = DateTime.now();
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    List<TransactionItem> walletTxs = [];

    if (wallet.id != null) {
      walletTxs = finance.transactions
          .where((tx) => tx.walletId == wallet.id)
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      for (var tx in walletTxs) {
        if (tx.dateTime.year == now.year &&
            tx.dateTime.month == now.month) {
          if (tx.type == 'income') monthlyIncome += tx.amount;
          if (tx.type == 'expense') monthlyExpense += tx.amount;
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รายละเอียด',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.blueAccent),
                    tooltip: 'แก้ไขชื่อ / ไอคอน',
                    onPressed: () =>
                        _showEditWalletSheet(context, wallet, finance),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded,
                        color: Colors.blueAccent),
                    tooltip: 'ตั้งค่างบประมาณ',
                    onPressed: () =>
                        _showBudgetSheet(context, wallet, finance),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () =>
                        _showDeleteConfirm(context, finance),
                  ),
                  InkWell(
                    onTap: () {
                      _noteFocus.unfocus();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black54),
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
                  // ─── Wallet header (กดแก้ไขได้) ───────
                  GestureDetector(
                    onTap: () => _showEditWalletSheet(context, wallet, finance),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                wallet.emojiIcon.isNotEmpty
                                    ? wallet.emojiIcon
                                    : '👛',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('แตะเพื่อแก้ไข',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Balance ─────────────────────────
                  const Text('ยอดคงเหลือ',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(
                    '${currentBalance.toStringAsFixed(2)} บาท',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ─── Monthly summary ─────────────────
                  const Text('รอบเดือน',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox('รายจ่าย', monthlyExpense,
                            Colors.red.shade100, Colors.red),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInfoBox(
                            'รายรับ',
                            monthlyIncome,
                            Colors.lightGreen.shade200,
                            Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Budget section ───────────────────
                  if (wallet.monthlyBudget != null) ...[
                    _buildBudgetSection(wallet, monthlyExpense, finance),
                    const SizedBox(height: 20),
                  ] else ...[
                    // ปุ่มเชิญตั้งงบ (ถ้ายังไม่มี)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showBudgetSheet(context, wallet, finance),
                      icon: const Icon(Icons.add_chart_outlined,
                          size: 18),
                      label: const Text('ตั้งงบประมาณรายเดือน'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(
                            color: Colors.blueAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── Note ────────────────────────────
                  _buildSectionTitle('บันทึกช่วยจำ', '(แตะเพื่อแก้ไข)'),
                  TextField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'เพิ่มบันทึกช่วยจำ...',
                      hintStyle:
                          const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _noteFocus.unfocus(),
                  ),
                  const SizedBox(height: 20),

                  // ─── Transactions ─────────────────────
                  // ─── กราฟรายรับ/รายจ่าย ──────────────
                  _buildChartSection(context, wallet, walletTxs),
                  const SizedBox(height: 20),

                  // ─── รายรับประจำ ──────────────────────
                  _buildRecurringSection(context, wallet, finance),
                  const SizedBox(height: 20),

                  _buildSectionTitle('ธุรกรรม', ''),
                  _buildTransactionList(walletTxs),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Budget Section Widget
  // ──────────────────────────────────────────────────────
  Widget _buildBudgetSection(
      Wallet wallet, double spent, FinanceProvider finance) {
    final budget = wallet.monthlyBudget!;
    final ratio = finance.getBudgetUsageRatio(wallet.id!).clamp(0.0, 1.0);
    final percent = (ratio * 100);
    final status = finance.getBudgetStatus(wallet.id!);
    final remaining = budget - spent;

    Color barColor;
    Color bgColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case BudgetStatus.exceeded:
        barColor = Colors.red;
        bgColor = Colors.red.shade50;
        statusLabel = 'เกินงบแล้ว!';
        statusIcon = Icons.warning_rounded;
        break;
      case BudgetStatus.warning:
        barColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        statusLabel = 'ใกล้ถึงงบแล้ว';
        statusIcon = Icons.notifications_active_outlined;
        break;
      default:
        barColor = Colors.green;
        bgColor = Colors.green.shade50;
        statusLabel = 'อยู่ในงบ';
        statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(statusIcon, size: 18, color: barColor),
              const SizedBox(width: 6),
              Text(
                'งบประมาณเดือนนี้',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                    fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: barColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),

          // Numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ใช้ไป',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  Text('฿${spent.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: barColor)),
                ],
              ),
              Text('${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: barColor)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remaining >= 0 ? 'คงเหลือ' : 'เกินไป',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    '฿${remaining.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remaining >= 0
                            ? Colors.green
                            : Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'งบทั้งหมด ฿${budget.toStringAsFixed(0)} / เดือน  •  แจ้งเตือนที่ ${(wallet.alertPercent ?? 80).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Bottom Sheet ตั้งค่า Budget
  // ──────────────────────────────────────────────────────
  void _showBudgetSheet(
      BuildContext context, Wallet wallet, FinanceProvider finance) {
    final budgetCtrl = TextEditingController(
      text: wallet.monthlyBudget?.toStringAsFixed(0) ?? '',
    );
    final lowBalCtrl = TextEditingController(
      text: wallet.lowBalanceThreshold?.toStringAsFixed(0) ?? '',
    );
    double alertPct = wallet.alertPercent ?? 80;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(wallet.emojiIcon,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Text(
                          'ตั้งงบ — ${wallet.name}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── งบประมาณต่อเดือน ──────────────
                    const Text('งบรายจ่ายต่อเดือน',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: budgetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'เช่น 5000',
                        prefixText: '฿ ',
                        suffixText: '/ เดือน',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── แจ้งเตือนที่ % ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('แจ้งเตือนเมื่อใช้ถึง',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(
                          '${alertPct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: alertPct >= 90
                                  ? Colors.red
                                  : alertPct >= 70
                                      ? Colors.orange
                                      : Colors.green),
                        ),
                      ],
                    ),
                    Slider(
                      value: alertPct,
                      min: 50,
                      max: 100,
                      divisions: 10,
                      activeColor: alertPct >= 90
                          ? Colors.red
                          : alertPct >= 70
                              ? Colors.orange
                              : Colors.green,
                      label: '${alertPct.toStringAsFixed(0)}%',
                      onChanged: (v) => setSS(() => alertPct = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('50%',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                        Text('100%',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── แจ้งเตือนเงินเหลือน้อย ────────
                    const Text('แจ้งเตือนเมื่อเงินคงเหลือต่ำกว่า',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lowBalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'เช่น 500 (ว่าง = ไม่แจ้งเตือน)',
                        prefixText: '฿ ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── ปุ่มบันทึก ────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final budget = double.tryParse(
                              budgetCtrl.text.trim());
                          final lowBal = double.tryParse(
                              lowBalCtrl.text.trim());

                          final updated = wallet.copyWith(
                            monthlyBudget: budget,
                            alertPercent: alertPct,
                            lowBalanceThreshold: lowBal,
                            clearMonthlyBudget: budget == null,
                            clearLowBalance: lowBal == null,
                          );
                          await finance.updateWallet(updated);
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('บันทึก',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white)),
                      ),
                    ),

                    // ปุ่มล้างงบ
                    if (wallet.monthlyBudget != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: () async {
                            final cleared = wallet.copyWith(
                              clearMonthlyBudget: true,
                              clearAlertPercent: true,
                              clearLowBalance: true,
                            );
                            await finance.updateWallet(cleared);
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text('ลบงบประมาณ',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────
  // Helper Widgets
  // ──────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────
  // Chart Section — รายรับ/รายจ่ายรายเดือน + ปีนี้
  // ──────────────────────────────────────────────────────
  Widget _buildChartSection(BuildContext context, Wallet wallet,
      List<TransactionItem> walletTxs) {
    return _ChartSection(wallet: wallet, transactions: walletTxs);
  }

  // ──────────────────────────────────────────────────────
  // Recurring Income/Expense Section
  // ──────────────────────────────────────────────────────
  Widget _buildRecurringSection(
      BuildContext context, Wallet wallet, FinanceProvider finance) {
    final rules = finance.getRulesForWallet(wallet.id!);
    final incomeRules  = rules.where((r) => r.txType == 'income').toList();
    final expenseRules = rules.where((r) => r.txType == 'expense').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('รายการประจำ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showRuleSheet(context, wallet, finance, null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่ม', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (rules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ยังไม่มีรายการประจำ\nกด + เพิ่มได้เลย เช่น เงินเดือน, ค่าเช่า, ค่าไฟ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          if (incomeRules.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('💰 รายรับ',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700,
                      fontWeight: FontWeight.w600)),
            ),
            ...incomeRules.map((rule) => _buildRuleCard(context, rule, finance)),
          ],
          if (expenseRules.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text('💸 รายจ่าย',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700,
                      fontWeight: FontWeight.w600)),
            ),
            ...expenseRules.map((rule) => _buildRuleCard(context, rule, finance)),
          ],
        ],
      ],
    );
  }

  Widget _buildRuleCard(
      BuildContext context, RecurringRule rule, FinanceProvider finance) {
    final isExp   = rule.txType == 'expense';
    final color   = isExp ? Colors.red : Colors.green;
    final bgColor = rule.isActive ? color.shade50  : Colors.grey.shade100;
    final bdColor = rule.isActive ? color.shade200 : Colors.grey.shade300;
    final icColor = rule.isActive ? color.shade700 : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: rule.isActive ? color.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExp ? Icons.remove_circle_outline : Icons.repeat,
              size: 18, color: icColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13,
                        color: rule.isActive ? Colors.black87 : Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  '${isExp ? '-' : '+'}฿${rule.amount.toStringAsFixed(0)}  •  ${rule.frequencyLabel}',
                  style: TextStyle(fontSize: 11, color: rule.isActive ? icColor : Colors.grey),
                ),
                if (rule.lastRunAt != null)
                  Text(
                    'ล่าสุด: ${rule.lastRunAt!.day}/${rule.lastRunAt!.month}/${rule.lastRunAt!.year}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Switch(
            value: rule.isActive,
            onChanged: (_) => finance.toggleRecurringRule(rule.id!),
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
            onPressed: () => _showRuleSheet(
                context,
                finance.wallets.firstWhere((w) => w.id == rule.walletId),
                finance, rule),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _confirmDeleteRule(context, rule, finance),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Bottom Sheet เพิ่ม/แก้ไข Rule (รองรับ income + expense)
  // ──────────────────────────────────────────────────────
  void _showRuleSheet(BuildContext context, Wallet wallet,
      FinanceProvider finance, RecurringRule? existing) {
    final labelCtrl  = TextEditingController(text: existing?.label ?? '');
    final amountCtrl = TextEditingController(
        text: existing?.amount.toStringAsFixed(0) ?? '');
    String txType          = existing?.txType ?? 'income';
    String selectedFreq    = existing?.frequency ?? 'monthly';
    int    selectedDay     = existing?.dayValue ?? 25;
    String? selectedCategory = existing?.category;

    const expenseCats = ['อาหาร','เดินทาง','ค่าเช่า','ค่าไฟ/น้ำ','ค่ารักษา','เบี้ยประกัน','อื่นๆ'];
    const incomeCats  = ['เงินเดือน','โบนัส','ธุรกิจ','ค่าเช่า','อื่นๆ'];
    const weekdays    = {1:'จันทร์',2:'อังคาร',3:'พุธ',4:'พฤหัส',5:'ศุกร์',6:'เสาร์',7:'อาทิตย์'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSS) {
          final cats = txType == 'expense' ? expenseCats : incomeCats;
          if (selectedCategory == null || !cats.contains(selectedCategory)) {
            selectedCategory = cats.first;
          }
          final accentColor = txType == 'expense' ? Colors.red : Colors.green;

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
                  Text(existing == null ? 'เพิ่มรายการประจำ' : 'แก้ไขรายการประจำ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // ── ประเภท income / expense ───────────
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => setSS(() {
                        txType = 'income';
                        selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: txType == 'income' ? Colors.green.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: txType == 'income' ? Colors.green.shade400 : Colors.grey.shade300),
                        ),
                        child: Text('💰 รายรับ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13,
                                color: txType == 'income' ? Colors.green.shade800 : Colors.grey)),
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(
                      onTap: () => setSS(() {
                        txType = 'expense';
                        selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: txType == 'expense' ? Colors.red.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: txType == 'expense' ? Colors.red.shade400 : Colors.grey.shade300),
                        ),
                        child: Text('💸 รายจ่าย',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13,
                                color: txType == 'expense' ? Colors.red.shade800 : Colors.grey)),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // ชื่อรายการ
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อรายการ *',
                      hintText: txType == 'income' ? 'เช่น เงินเดือน' : 'เช่น ค่าเช่า, ค่าไฟ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // จำนวนเงิน
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'จำนวนเงิน *',
                      prefixText: '฿ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // หมวดหมู่
                  const Text('หมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: cats.map((cat) {
                    final sel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: accentColor.shade100,
                      onSelected: (_) => setSS(() => selectedCategory = cat),
                    );
                  }).toList()),
                  const SizedBox(height: 16),

                  // ความถี่
                  const Text('ความถี่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _freqChip('รายเดือน', 'monthly', selectedFreq, accentColor,
                        (v) => setSS(() { selectedFreq = v; selectedDay = 25; })),
                    const SizedBox(width: 8),
                    _freqChip('รายสัปดาห์', 'weekly', selectedFreq, accentColor,
                        (v) => setSS(() { selectedFreq = v; selectedDay = 1; })),
                    const SizedBox(width: 8),
                    _freqChip('ทุกวัน', 'daily', selectedFreq, accentColor,
                        (v) => setSS(() { selectedFreq = v; selectedDay = 0; })),
                  ]),
                  const SizedBox(height: 14),

                  // วัน/วันที่
                  if (selectedFreq == 'monthly') ...[
                    Row(children: [
                      Text(txType == 'income' ? 'วันที่เงินเข้า' : 'วันที่หักเงิน',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.shade200),
                        ),
                        child: Text('วันที่ $selectedDay',
                            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor.shade700)),
                      ),
                    ]),
                    Slider(
                      value: selectedDay.toDouble(), min: 1, max: 31, divisions: 30,
                      activeColor: accentColor,
                      label: 'วันที่ $selectedDay',
                      onChanged: (v) => setSS(() => selectedDay = v.round()),
                    ),
                  ] else if (selectedFreq == 'weekly') ...[
                    const Text('วันในสัปดาห์',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: weekdays.entries.map((e) {
                      final sel = selectedDay == e.key;
                      return ChoiceChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        selectedColor: accentColor.shade100,
                        onSelected: (_) => setSS(() => selectedDay = e.key),
                      );
                    }).toList()),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 16, color: accentColor.shade700),
                        const SizedBox(width: 8),
                        Text(
                          txType == 'income'
                              ? 'เงินจะเข้าทุกวันที่เปิดแอป'
                              : 'จะหักเงินทุกวันที่เปิดแอป',
                          style: TextStyle(fontSize: 12, color: accentColor.shade700)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final label  = labelCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (label.isEmpty || amount == null || amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('กรุณากรอกชื่อและจำนวนเงินให้ครบ')));
                          return;
                        }
                        final rule = RecurringRule(
                          id: existing?.id,
                          walletId: wallet.id!,
                          label: label,
                          amount: amount,
                          category: selectedCategory ?? cats.first,
                          frequency: selectedFreq,
                          dayValue: selectedDay,
                          isActive: existing?.isActive ?? true,
                          lastRunAt: existing?.lastRunAt,
                          txType: txType,
                        );
                        if (existing == null) {
                          await finance.addRecurringRule(rule);
                        } else {
                          await finance.updateRecurringRule(rule);
                        }
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(
                        existing == null ? 'เพิ่มรายการประจำ' : 'บันทึกการแก้ไข',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget _freqChip(String label, String value, String current,
      MaterialColor accentColor, Function(String) onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? accentColor.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? accentColor.shade300 : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? accentColor.shade800 : Colors.grey.shade700)),
      ),
    );
  }

  void _confirmDeleteRule(
      BuildContext context, RecurringRule rule, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการประจำ?'),
        content: Text('ต้องการลบ "${rule.label}" ใช่ไหม?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await finance.deleteRecurringRule(rule.id!);
              Navigator.pop(ctx);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text('ยังไม่มีรายการ',
            style: TextStyle(color: Colors.grey)),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(tx.category,
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildInfoBox(
      String title, double amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            '${amount.toStringAsFixed(2)} บาท',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Edit Wallet Name / Icon
  // ──────────────────────────────────────────────────────
  void _showEditWalletSheet(
      BuildContext context, Wallet wallet, FinanceProvider finance) {
    final nameCtrl = TextEditingController(text: wallet.name);
    String selectedEmoji = wallet.emojiIcon.isNotEmpty ? wallet.emojiIcon : '👛';
    final emojiList = ['💰','👛','💳','🏦','💵','🪙','💎','🛒','🏠','🚗','✈️','🎮','📱','🎓','💊','🍜'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSS) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('แก้ไขกระเป๋า',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Emoji grid
                Wrap(spacing: 10, runSpacing: 10, children: emojiList.map((e) {
                  final sel = e == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setSS(() => selectedEmoji = e),
                    child: Container(
                      width: 48, height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: sel ? Border.all(color: Colors.blueAccent, width: 2) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),

                // ชื่อกระเป๋า
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ชื่อกระเป๋า',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Text(selectedEmoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      await finance.updateWallet(wallet.copyWith(
                        name: name, emojiIcon: selectedEmoji,
                      ));
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('แก้ไขกระเป๋าเรียบร้อย')),
                      );
                    },
                    child: const Text('บันทึก',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  void _showDeleteConfirm(
      BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบกระเป๋าตังค์?'),
        content: Text(
            'แน่ใจหรือไม่ว่าต้องการลบ "${widget.wallet.name}" ข้อมูลธุรกรรมทั้งหมดจะหายไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (widget.wallet.id != null) {
                await finance.deleteWallet(widget.wallet.id!);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'ลบกระเป๋า "${widget.wallet.name}" เรียบร้อย')),
              );
            },
            child: const Text('ลบเลย',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// _ChartSection — Bar chart รายรับ/รายจ่ายต่อเดือน
// ════════════════════════════════════════════════════════
class _ChartSection extends StatefulWidget {
  final Wallet wallet;
  final List<TransactionItem> transactions;

  const _ChartSection(
      {Key? key, required this.wallet, required this.transactions})
      : super(key: key);

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  // 'month' = เดือนปัจจุบัน แยกตามหมวด | 'year' = รายเดือนทั้งปี
  String _mode = 'year';
  int _touchedIndex = -1;

  static const _monthNames = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + toggle
        Row(
          children: [
            const Text('สถิติ',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            _modeBtn('ทั้งปี', 'year'),
            const SizedBox(width: 8),
            _modeBtn('เดือนนี้', 'month'),
          ],
        ),
        const SizedBox(height: 12),

        _mode == 'year'
            ? _buildYearChart()
            : _buildMonthCategoryChart(),
      ],
    );
  }

  Widget _modeBtn(String label, String value) {
    final sel = _mode == value;
    return GestureDetector(
      onTap: () => setState(() { _mode = value; _touchedIndex = -1; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.blueAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? Colors.blueAccent : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  // ── ทั้งปี: bar chart รายได้ vs รายจ่ายแต่ละเดือน ──
  Widget _buildYearChart() {
    final now = DateTime.now();
    final year = now.year;

    // คำนวณยอดแต่ละเดือน
    final List<double> incomes  = List.filled(12, 0);
    final List<double> expenses = List.filled(12, 0);

    for (final tx in widget.transactions) {
      if (tx.dateTime.year != year) continue;
      final m = tx.dateTime.month - 1;
      if (tx.type == 'income')  incomes[m]  += tx.amount;
      if (tx.type == 'expense') expenses[m] += tx.amount;
    }

    final maxY = [
      ...incomes, ...expenses, 100.0
    ].reduce((a, b) => a > b ? a : b);

    final barGroups = List.generate(12, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: incomes[i],
            color: Colors.green.shade400,
            width: 7,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expenses[i],
            color: Colors.red.shade300,
            width: 7,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Column(
        children: [
          // Legend
          Row(children: [
            _legendDot(Colors.green.shade400, 'รายรับ'),
            const SizedBox(width: 16),
            _legendDot(Colors.red.shade300, 'รายจ่าย'),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueAccent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'รายรับ' : 'รายจ่าย';
                      return BarTooltipItem(
                        '$label\n฿${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final v = value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : value.toStringAsFixed(0);
                        return Text(v,
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(_monthNames[value.toInt() + 1],
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawHorizontalLine: true,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200, strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── เดือนนี้: pie/bar แยกตามหมวดหมู่รายจ่าย ──────
  Widget _buildMonthCategoryChart() {
    final now = DateTime.now();

    // รวมรายจ่ายตามหมวดเดือนนี้
    final Map<String, double> catMap = {};
    for (final tx in widget.transactions) {
      if (tx.type != 'expense') continue;
      if (tx.dateTime.year != now.year || tx.dateTime.month != now.month) continue;
      catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
    }

    if (catMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: const Center(
          child: Text('ไม่มีรายจ่ายเดือนนี้ 🎉',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);

    final colors = [
      Colors.redAccent, Colors.orange, Colors.amber,
      Colors.purple, Colors.teal, Colors.indigo,
      Colors.pink, Colors.cyan, Colors.lime,
    ];

    final sections = List.generate(sorted.length, (i) {
      final pct = sorted[i].value / total * 100;
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: sorted[i].value,
        color: colors[i % colors.length],
        radius: isTouched ? 70 : 58,
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text('รายจ่ายเดือนนี้ ฿${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Pie chart
              SizedBox(
                height: 160, width: 160,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(sorted.length, (i) {
                    final pct = sorted[i].value / total * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(sorted[i].key,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors[i % colors.length])),
                      ]),
                    );
                  }),
                ),
              ),
            ],
          ),
          // Highlight category ที่แตะ
          if (_touchedIndex >= 0 && _touchedIndex < sorted.length) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors[_touchedIndex % colors.length].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sorted[_touchedIndex].key,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors[_touchedIndex % colors.length])),
                  const SizedBox(width: 8),
                  Text('฿${sorted[_touchedIndex].value.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors[_touchedIndex % colors.length])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

