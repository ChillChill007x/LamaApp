import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({Key? key}) : super(key: key);

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime _currentMonth = DateTime.now();

  // ชื่อวันในสัปดาห์
  final List<String> _weekDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  // ฟังก์ชันเปลี่ยนเดือน
  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  // แปลงเดือนเป็นภาษาไทย
  String _getMonthName(int month) {
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    // คำนวณวันแรกและจำนวนวันในเดือนนี้
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    
    // หาวันแรกของเดือนว่าตรงกับวันอะไร (0 = อาทิตย์, 1 = จันทร์ ... 6 = เสาร์)
    int startingWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          // ส่วนหัวปฏิทิน (เลื่อนเดือนได้)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year + 543}', // แสดงปี พ.ศ.
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // หัวตาราง (จ, อ, พ, ...)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((day) => 
              SizedBox(
                width: 40, 
                child: Center(
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                )
              )
            ).toList(),
          ),
          const SizedBox(height: 10),

          // ตัวตารางปฏิทิน
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 สัปดาห์ * 7 วัน (ครอบคลุมทุกเดือน)
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8, // ปรับอัตราส่วนให้กล่องสูงขึ้นนิดนึงเพื่อใส่ตัวเลขเงิน
            ),
            itemBuilder: (context, index) {
              int dayIndex = index - startingWeekday + 1;

              // ถ้าไม่ใช่ช่องของวันในเดือนนี้ ให้เป็นช่องว่าง
              if (dayIndex <= 0 || dayIndex > daysInMonth) {
                return const SizedBox();
              }

              DateTime currentDate = DateTime(_currentMonth.year, _currentMonth.month, dayIndex);
              bool isToday = currentDate.year == DateTime.now().year &&
                             currentDate.month == DateTime.now().month &&
                             currentDate.day == DateTime.now().day;

              // คำนวณรายจ่ายเฉพาะของวันนี้
              double dailyExpense = 0;
              for (var tx in provider.transactions) {
                if (tx.type == 'expense' && 
                    tx.dateTime.year == currentDate.year &&
                    tx.dateTime.month == currentDate.month &&
                    tx.dateTime.day == currentDate.day) {
                  dailyExpense += tx.amount;
                }
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: Colors.blueAccent) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayIndex',
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.blueAccent : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // ถ้าวันนี้มีรายจ่าย ให้โชว์ตัวเลขสีแดง
                    if (dailyExpense > 0)
                      Text(
                        '-${dailyExpense.toInt()}', // โชว์แค่จำนวนเต็มให้ประหยัดพื้นที่
                        style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}