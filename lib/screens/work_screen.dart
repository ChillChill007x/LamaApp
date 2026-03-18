import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/task_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
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
    return Consumer<FinanceProvider>(builder: (context, finance, _) {
      final pending = finance.pendingTasks;
      final done    = finance.doneTasks;

      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('ตารางงาน',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: TabBar(
            controller: _tab,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: '📋 รอดำเนินการ (${pending.length})'),
              Tab(text: '✅ เสร็จแล้ว (${done.length})'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildTaskList(pending, finance, isDone: false),
            _buildTaskList(done, finance, isDone: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTaskSheet(context, finance, null),
          backgroundColor: Colors.blueAccent,
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มงาน'),
        ),
      );
    });
  }

  // ──────────────────────────────────────────────────────
  // Task List
  // ──────────────────────────────────────────────────────
  Widget _buildTaskList(List<TaskItem> tasks, FinanceProvider finance,
      {required bool isDone}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isDone ? Icons.check_circle_outline : Icons.assignment_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(isDone ? 'ยังไม่มีงานที่เสร็จ' : 'ไม่มีงานค้าง 🎉',
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) => _buildTaskCard(tasks[i], finance),
    );
  }

  Widget _buildTaskCard(TaskItem task, FinanceProvider finance) {
    final isOverdue = task.status == 'overdue';
    final isDone    = task.status == 'done';
    final now       = DateTime.now();

    String timeLeft = '';
    if (!isDone) {
      final diff = task.deadline.difference(now);
      if (diff.isNegative) {
        final days = (-diff.inHours / 24).ceil();
        timeLeft = 'เลยกำหนด $days วัน';
      } else if (diff.inDays > 0) {
        timeLeft = 'อีก ${diff.inDays} วัน';
      } else if (diff.inHours > 0) {
        timeLeft = 'อีก ${diff.inHours} ชม.';
      } else {
        timeLeft = 'อีก ${diff.inMinutes} นาที';
      }
    }

    Color borderColor = isDone
        ? Colors.green.shade200
        : isOverdue ? Colors.red.shade300 : Colors.grey.shade200;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Checkbox
            GestureDetector(
              onTap: () async {
                if (isDone) {
                  await finance.markTaskPending(task.id!);
                } else {
                  await finance.markTaskDone(task.id!);
                }
              },
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isDone ? Colors.green
                        : isOverdue ? Colors.red : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : Colors.black87,
              ),
            )),
            if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text('เลยกำหนด',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              onSelected: (v) async {
                if (v == 'edit') _showTaskSheet(context, finance, task);
                if (v == 'delete') _confirmDelete(context, finance, task);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                const PopupMenuItem(value: 'delete',
                    child: Text('ลบ', style: TextStyle(color: Colors.red))),
              ],
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: isOverdue ? Colors.red : Colors.grey),
            const SizedBox(width: 5),
            Text(
              '${task.deadline.day}/${task.deadline.month}/${task.deadline.year}  '
              '${task.deadline.hour.toString().padLeft(2,'0')}:${task.deadline.minute.toString().padLeft(2,'0')} น.',
              style: TextStyle(fontSize: 12,
                  color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600),
            ),
            if (timeLeft.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('• $timeLeft',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isOverdue ? Colors.red : Colors.blueAccent)),
            ],
          ]),
          if (task.note != null && task.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(task.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Add / Edit Sheet
  // ──────────────────────────────────────────────────────
  void _showTaskSheet(BuildContext context, FinanceProvider finance,
      TaskItem? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl  = TextEditingController(text: existing?.note ?? '');

    DateTime selectedDate = existing?.deadline ??
        DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.deadline.hour, minute: existing.deadline.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    int notifyMinsBefore = 1440; // default 1 วัน

    const notifyOptions = [
      {'label': '5 นาที',     'minutes': 5},
      {'label': '30 นาที',    'minutes': 30},
      {'label': '1 ชั่วโมง', 'minutes': 60},
      {'label': '3 ชั่วโมง', 'minutes': 180},
      {'label': '1 วัน',     'minutes': 1440},
      {'label': '2 วัน',     'minutes': 2880},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSS) {
          final deadline = DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day,
            selectedTime.hour, selectedTime.minute,
          );
          final notifyAt = deadline.subtract(Duration(minutes: notifyMinsBefore));

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
                  Text(existing == null ? 'เพิ่มงาน' : 'แก้ไขงาน',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // ชื่องาน
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'ชื่องาน *',
                      prefixIcon: const Icon(Icons.assignment_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── วันและเวลาครบกำหนด ───────────────────
                  const Text('วันและเวลาครบกำหนด',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    // เลือกวัน
                    Expanded(child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setSS(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 14)),
                        ]),
                      ),
                    )),
                    const SizedBox(width: 10),
                    // เลือกเวลา ── ปุ่มสำคัญใหม่
                    Expanded(child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                          builder: (context, child) => MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          ),
                        );
                        if (picked != null) setSS(() => selectedTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2,'0')}:'
                            '${selectedTime.minute.toString().padLeft(2,'0')} น.',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                        ]),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // ── แจ้งเตือนล่วงหน้า ─────────────────────
                  const Text('แจ้งเตือนล่วงหน้า',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: notifyOptions.map((opt) {
                      final mins = opt['minutes'] as int;
                      final sel  = notifyMinsBefore == mins;
                      return ChoiceChip(
                        label: Text(opt['label'] as String,
                            style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        selectedColor: Colors.blue.shade100,
                        onSelected: (_) => setSS(() => notifyMinsBefore = mins),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // แสดงเวลาแจ้งเตือนจริง
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.notifications_outlined,
                          size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'จะแจ้งเตือน: ${notifyAt.day}/${notifyAt.month}/${notifyAt.year}  '
                        '${notifyAt.hour.toString().padLeft(2,'0')}:${notifyAt.minute.toString().padLeft(2,'0')} น.',
                        style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // บันทึกช่วยจำ
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'บันทึกช่วยจำ (ไม่บังคับ)',
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('กรุณากรอกชื่องาน')));
                          return;
                        }
                        final fullDeadline = DateTime(
                          selectedDate.year, selectedDate.month, selectedDate.day,
                          selectedTime.hour, selectedTime.minute,
                        );
                        final notifyTime = fullDeadline.subtract(
                            Duration(minutes: notifyMinsBefore));

                        if (existing == null) {
                          final task = TaskItem(
                            title: title,
                            deadline: fullDeadline,
                            note: noteCtrl.text.trim().isEmpty
                                ? null : noteCtrl.text.trim(),
                            createdAt: DateTime.now(),
                          );
                          await finance.addTaskWithNotify(task, notifyTime);
                        } else {
                          final updated = existing.copyWith(
                            title: title,
                            deadline: fullDeadline,
                            note: noteCtrl.text.trim().isEmpty
                                ? null : noteCtrl.text.trim(),
                          );
                          await finance.updateTaskWithNotify(updated, notifyTime);
                        }
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(existing == null ? 'บันทึกงาน' : 'บันทึกการแก้ไข',
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

  void _confirmDelete(BuildContext context, FinanceProvider finance, TaskItem task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบงาน?'),
        content: Text('ต้องการลบ "${task.title}" ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await finance.deleteTask(task.id!);
              Navigator.pop(ctx);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
