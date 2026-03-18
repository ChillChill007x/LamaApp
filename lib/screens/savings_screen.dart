import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/savings_goal_model.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('ออมเงิน & โอน',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            bottom: TabBar(
              controller: _tab,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(text: '🎯 เป้าหมายออม (${finance.activeSavingsGoals.length})'),
                const Tab(text: '💸 โอนเงิน'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _SavingsGoalsTab(finance: finance),
              _TransferTab(finance: finance),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tab,
            builder: (_, __) => _tab.index == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _showGoalSheet(context, finance, null),
                    backgroundColor: Colors.blueAccent,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มเป้าหมาย'),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  void _showGoalSheet(BuildContext context, FinanceProvider finance,
      SavingsGoal? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(
        text: existing?.targetAmount.toStringAsFixed(0) ?? '');
    String emoji = existing?.emoji ?? '🎯';
    DateTime deadline = existing?.deadline ??
        DateTime.now().add(const Duration(days: 90));
    int? walletId = existing?.walletId ??
        (finance.wallets.isNotEmpty ? finance.wallets.first.id : null);

    const emojis = ['🎯','🏠','🚗','✈️','💻','📱','💍','🎓','💊','🏖️','🎮','💰'];

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(existing == null ? 'เพิ่มเป้าหมายออม' : 'แก้ไขเป้าหมาย',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Emoji picker
                  Wrap(spacing: 10, runSpacing: 10, children: emojis.map((e) {
                    final sel = e == emoji;
                    return GestureDetector(
                      onTap: () => setSS(() => emoji = e),
                      child: Container(
                        width: 44, height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: sel ? Border.all(color: Colors.blueAccent, width: 2) : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 14),

                  // ชื่อเป้าหมาย
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อเป้าหมาย *',
                      hintText: 'เช่น ซื้อรถ, เที่ยวญี่ปุ่น',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Text('  $emoji', style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // จำนวนเงิน
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'เป้าหมาย *',
                      prefixText: '฿ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // กระเป๋า
                  if (finance.wallets.isNotEmpty) ...[
                    const Text('กระเป๋าที่ใช้ออม',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: walletId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: finance.wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.emojiIcon} ${w.name}'),
                      )).toList(),
                      onChanged: (v) => setSS(() => walletId = v),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // วันที่อยากถึงเป้า
                  const Text('อยากถึงเป้าภายใน',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: deadline,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSS(() => deadline = picked);
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
                        Text('${deadline.day}/${deadline.month}/${deadline.year}'),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ]),
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
                        final title = titleCtrl.text.trim();
                        final target = double.tryParse(targetCtrl.text.trim());
                        if (title.isEmpty || target == null || walletId == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
                          return;
                        }
                        final goal = SavingsGoal(
                          id: existing?.id,
                          title: title,
                          emoji: emoji,
                          targetAmount: target,
                          savedAmount: existing?.savedAmount ?? 0,
                          deadline: deadline,
                          walletId: walletId!,
                        );
                        if (existing == null) {
                          await finance.addSavingsGoal(goal);
                        } else {
                          await finance.updateSavingsGoal(goal);
                        }
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(existing == null ? 'สร้างเป้าหมาย' : 'บันทึก',
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
}

// ──────────────────────────────────────────────────────
// Tab 1: Savings Goals
// ──────────────────────────────────────────────────────
class _SavingsGoalsTab extends StatelessWidget {
  final FinanceProvider finance;
  const _SavingsGoalsTab({required this.finance});

  @override
  Widget build(BuildContext context) {
    final active   = finance.savingsGoals.where((g) => !g.isCompleted).toList();
    final completed = finance.savingsGoals.where((g) => g.isCompleted).toList();

    if (finance.savingsGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯', style: TextStyle(fontSize: 56, color: Colors.grey.shade300)),
            const SizedBox(height: 12),
            const Text('ยังไม่มีเป้าหมายการออม\nกด + เพื่อเพิ่มเลย',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (active.isNotEmpty) ...[
          const Text('กำลังดำเนินการ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...active.map((g) => _GoalCard(goal: g, finance: finance)),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          const Text('สำเร็จแล้ว 🎉',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...completed.map((g) => _GoalCard(goal: g, finance: finance)),
        ],
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final FinanceProvider finance;
  const _GoalCard({required this.goal, required this.finance});

  @override
  Widget build(BuildContext context) {
    final wallet = finance.wallets.firstWhere(
      (w) => w.id == goal.walletId,
      orElse: () => finance.wallets.isNotEmpty
          ? finance.wallets.first
          : throw Exception('No wallets'),
    );
    final walletBalance = finance.getWalletBalance(goal.walletId);

    Color barColor = goal.isCompleted
        ? Colors.green
        : goal.progressRatio >= 0.8
            ? Colors.orange
            : Colors.blueAccent;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: goal.isCompleted
            ? BorderSide(color: Colors.green.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${wallet.emojiIcon} ${wallet.name}  •  '
                          '${goal.daysLeft > 0 ? 'อีก ${goal.daysLeft} วัน' : 'ถึงกำหนดแล้ว'}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (!goal.isCompleted) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => _showAddSavingSheet(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      final parent = context.findAncestorStateOfType<_SavingsScreenState>();
                      parent?._showGoalSheet(context, finance, goal);
                    } else if (v == 'delete') {
                      await finance.deleteSavingsGoal(goal.id!);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                    const PopupMenuItem(value: 'delete',
                        child: Text('ลบ', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('฿${goal.savedAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: barColor, fontSize: 16)),
                Text('${(goal.progressRatio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: barColor)),
                Text('฿${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progressRatio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),

            if (!goal.isCompleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ยังขาดอีก ฿${goal.remaining.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('ต้องออมเดือนละ ฿${goal.monthlyNeeded.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )
            else
              const Text('✅ บรรลุเป้าหมายแล้ว!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showAddSavingSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final walletBalance = finance.getWalletBalance(goal.walletId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('ออมเงินเข้า "${goal.title}"',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('คงเหลือในกระเป๋า ฿${walletBalance.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Quick amount buttons
              Row(
                children: [500, 1000, 2000, 5000].map((v) =>
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => amountCtrl.text = v.toString(),
                      child: Text('฿$v', style: const TextStyle(fontSize: 12)),
                    ),
                  ))
                ).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    if (amount > walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เงินในกระเป๋าไม่พอ')));
                      return;
                    }
                    await finance.addSaving(goal: goal, amount: amount);
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ออมเงิน ฿${amount.toStringAsFixed(0)} เรียบร้อย')));
                  },
                  child: const Text('ออมเงิน',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────
// Tab 2: Transfer
// ──────────────────────────────────────────────────────
class _TransferTab extends StatefulWidget {
  final FinanceProvider finance;
  const _TransferTab({required this.finance});

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  int? _fromId;
  int? _toId;
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final wallets = widget.finance.wallets;
    if (wallets.length >= 2) {
      _fromId = wallets[0].id;
      _toId   = wallets[1].id;
    } else if (wallets.length == 1) {
      _fromId = wallets[0].id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.finance.wallets;
    if (wallets.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('ต้องมีกระเป๋าอย่างน้อย 2 ใบ\nเพื่อโอนเงินระหว่างกระเป๋า',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      );
    }

    final fromBalance = _fromId != null
        ? widget.finance.getWalletBalance(_fromId!)
        : 0.0;
    final fromWallet = _fromId != null
        ? wallets.firstWhere((w) => w.id == _fromId)
        : null;
    final toWallet = _toId != null
        ? wallets.firstWhere((w) => w.id == _toId)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From
          const Text('จากกระเป๋า',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _fromId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            items: wallets.map((w) => DropdownMenuItem(
              value: w.id,
              child: Row(children: [
                Text(w.emojiIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text('฿${widget.finance.getWalletBalance(w.id!).toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            )).toList(),
            onChanged: (v) => setState(() {
              _fromId = v;
              if (_toId == v) _toId = wallets.firstWhere((w) => w.id != v).id;
            }),
          ),
          const SizedBox(height: 8),
          if (fromWallet != null)
            Text('คงเหลือ ฿${fromBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          // Arrow
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward, color: Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 16),

          // To
          const Text('ไปยังกระเป๋า',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _toId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            items: wallets
                .where((w) => w.id != _fromId)
                .map((w) => DropdownMenuItem(
              value: w.id,
              child: Row(children: [
                Text(w.emojiIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text('฿${widget.finance.getWalletBalance(w.id!).toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _toId = v),
          ),
          const SizedBox(height: 20),

          // Amount
          const Text('จำนวนเงิน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '฿ ',
              hintText: '0',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          // Quick amounts
          Row(
            children: [1000, 2000, 5000, 10000].map((v) =>
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: OutlinedButton(
                  onPressed: () => setState(() => _amountCtrl.text = v.toString()),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text('฿$v', style: const TextStyle(fontSize: 12)),
                ),
              ))
            ).toList(),
          ),
          const SizedBox(height: 14),

          // Note
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'หมายเหตุ (ไม่บังคับ)',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Summary card
          if (_fromId != null && _toId != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(children: [
                      Text(fromWallet?.emojiIcon ?? '', style: const TextStyle(fontSize: 24)),
                      Text(fromWallet?.name ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                  Column(children: [
                    const Icon(Icons.arrow_forward, color: Colors.blueAccent),
                    Text(
                      _amountCtrl.text.isEmpty ? '' : '฿${_amountCtrl.text}',
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ]),
                  Expanded(
                    child: Column(children: [
                      Text(toWallet?.emojiIcon ?? '', style: const TextStyle(fontSize: 24)),
                      Text(toWallet?.name ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ปุ่มโอน
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text('โอนเงิน',
                  style: TextStyle(fontSize: 17, color: Colors.white)),
              onPressed: _isLoading ? null : () async {
                final amount = double.tryParse(_amountCtrl.text.trim());
                if (_fromId == null || _toId == null || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
                  return;
                }
                if (_fromId == _toId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กระเป๋าต้นทางและปลายทางต้องไม่ใช่ใบเดียวกัน')));
                  return;
                }
                if (amount > fromBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เงินในกระเป๋าไม่เพียงพอ')));
                  return;
                }
                setState(() => _isLoading = true);
                await widget.finance.transfer(
                  fromWalletId: _fromId!,
                  toWalletId: _toId!,
                  amount: amount,
                  note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                );
                setState(() => _isLoading = false);
                _amountCtrl.clear();
                _noteCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    'โอน ฿${amount.toStringAsFixed(0)} เรียบร้อยแล้ว')));
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
