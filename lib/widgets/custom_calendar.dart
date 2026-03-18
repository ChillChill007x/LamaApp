import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({Key? key}) : super(key: key);

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime _currentMonth = DateTime.now();

  final List<String> _weekDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month];
  }

  // ── กดวัน → popup รายละเอียด ─────────────────────────
  void _showDayDetail(BuildContext context, DateTime date,
      FinanceProvider provider) {
    // กรองธุรกรรมและงานของวันที่เลือก
    final txs = provider.transactions.where((tx) =>
        tx.dateTime.year == date.year &&
        tx.dateTime.month == date.month &&
        tx.dateTime.day == date.day).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final tasks = provider.tasks.where((t) =>
        t.deadline.year == date.year &&
        t.deadline.month == date.month &&
        t.deadline.day == date.day).toList();

    final double totalIncome  = txs.where((t) => t.type == 'income')
        .fold(0, (s, t) => s + t.amount);
    final double totalExpense = txs.where((t) => t.type == 'expense')
        .fold(0, (s, t) => s + t.amount);

    final dateLabel =
        '${date.day} ${_getMonthName(date.month)} ${date.year + 543}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.90,
        builder: (_, scrollCtrl) => Column(children: [
          // handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(dateLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (totalIncome > 0)
                Text('+฿${totalIncome.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.green,
                        fontWeight: FontWeight.bold, fontSize: 13)),
              if (totalIncome > 0 && totalExpense > 0)
                const SizedBox(width: 8),
              if (totalExpense > 0)
                Text('-฿${totalExpense.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.red,
                        fontWeight: FontWeight.bold, fontSize: 13)),
              if (txs.isEmpty && tasks.isEmpty)
                Text('ไม่มีรายการ',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ]),
          ),
          const Divider(height: 1),

          // content
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                // งาน deadline
                if (tasks.isNotEmpty) ...[
                  _sectionLabel('📋 งานครบกำหนดวันนี้'),
                  ...tasks.map((t) => _taskTile(t)),
                  const SizedBox(height: 12),
                ],
                // ธุรกรรม
                if (txs.isNotEmpty) ...[
                  _sectionLabel('💰 รายการธุรกรรม'),
                  ...txs.map((tx) => _txTile(tx, provider)),
                ],
                // ว่างเปล่า
                if (txs.isEmpty && tasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.event_available,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('ไม่มีรายการในวันนี้',
                            style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _taskTile(TaskItem task) {
    final isOverdue = task.status == 'overdue';
    final isDone    = task.status == 'done';
    final bgColor   = isDone ? Colors.green.shade50
        : isOverdue ? Colors.red.shade50 : Colors.orange.shade50;
    final bdColor   = isDone ? Colors.green.shade200
        : isOverdue ? Colors.red.shade200 : Colors.orange.shade200;
    final iconColor = isDone ? Colors.green
        : isOverdue ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bdColor)),
      child: Row(children: [
        Icon(isDone ? Icons.check_circle : Icons.schedule,
            size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null)),
            Text(
              '${task.deadline.hour.toString().padLeft(2,'0')}:'
              '${task.deadline.minute.toString().padLeft(2,'0')} น.  •  '
              '${isDone ? 'เสร็จแล้ว' : isOverdue ? 'เลยกำหนด' : 'รอดำเนินการ'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _txTile(TransactionItem tx, FinanceProvider provider) {
    final isIncome = tx.type == 'income';
    final wallet   = provider.wallets.firstWhere(
      (w) => w.id == tx.walletId,
      orElse: () => provider.wallets.isNotEmpty
          ? provider.wallets.first : provider.wallets.first,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(children: [
              Text(
                '${tx.dateTime.hour.toString().padLeft(2,'0')}:'
                '${tx.dateTime.minute.toString().padLeft(2,'0')} น.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 6),
              Text('${wallet.emojiIcon} ${wallet.name}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ],
        )),
        Text(
          '${isIncome ? '+' : '-'}฿${tx.amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
              color: isIncome ? Colors.green : Colors.red),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final int startingWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(children: [
        // ── หัว ─────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1)),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year + 543}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1)),
        ]),
        const SizedBox(height: 4),

        // legend
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _dot(Colors.orange), const SizedBox(width: 4),
          Text('ครบกำหนด',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          _dot(Colors.red), const SizedBox(width: 4),
          Text('เลยกำหนด',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ]),
        const SizedBox(height: 8),

        // หัวตาราง
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays.map((day) => SizedBox(
            width: 40,
            child: Center(child: Text(day,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          )).toList(),
        ),
        const SizedBox(height: 6),

        // ── Grid ────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final dayIndex = index - startingWeekday + 1;
            if (dayIndex <= 0 || dayIndex > daysInMonth) return const SizedBox();

            final date = DateTime(_currentMonth.year, _currentMonth.month, dayIndex);
            final now  = DateTime.now();
            final isToday = date.year == now.year &&
                date.month == now.month && date.day == now.day;

            // รายจ่ายวัน
            double dailyExpense = 0;
            bool hasIncome = false;
            for (final tx in provider.transactions) {
              if (tx.dateTime.year == date.year &&
                  tx.dateTime.month == date.month &&
                  tx.dateTime.day == date.day) {
                if (tx.type == 'expense') dailyExpense += tx.amount;
                if (tx.type == 'income')  hasIncome = true;
              }
            }

            // dot งาน
            final taskKey = DateTime(date.year, date.month, date.day);
            final taskStatus = provider.taskDeadlineMap[taskKey];
            final dotColor = taskStatus == 'overdue' ? Colors.red
                : taskStatus == 'pending' ? Colors.orange : null;

            return GestureDetector(
              onTap: () => _showDayDetail(context, date, provider),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: Colors.blueAccent) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayIndex',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.blueAccent : Colors.black87,
                          fontSize: 13,
                        )),
                    if (dailyExpense > 0)
                      Text('-${dailyExpense.toInt()}',
                          style: const TextStyle(fontSize: 9,
                              color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    if (dotColor != null)
                      _dot(dotColor)
                    else if (hasIncome && dailyExpense == 0)
                      _dot(Colors.green),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _dot(Color color) => Container(
    width: 5, height: 5,
    margin: const EdgeInsets.only(top: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
