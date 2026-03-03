class TransactionItem {
  final int? id;
  final int walletId;     // ตัวระบุว่าธุรกรรมนี้เป็นของกระเป๋าใบไหน
  final String type;      // เก็บค่า 'income' (รายรับ) หรือ 'expense' (รายจ่าย)
  final double amount;    // จำนวนเงิน
  final String category;  // หมวดหมู่ เช่น ค่าอาหาร, ค่าเดินทาง, ค่าน้ำมัน
  final DateTime dateTime;// วันที่และเวลา
  final String? note;     // บันทึกช่วยจำเพิ่มเติม

  TransactionItem({
    this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.note,
  });

  // ฟังก์ชันแปลงข้อมูลเป็น Map เพื่อนำไปบันทึกลง SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'type': type,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.toIso8601String(), // แปลงวันที่ให้เป็นข้อความเพื่อให้ SQLite เก็บได้
      'note': note,
    };
  }

  // ฟังก์ชันสร้าง Object จาก Map ที่ดึงมาจาก SQLite
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      walletId: map['walletId'],
      type: map['type'],
      amount: map['amount'],
      category: map['category'],
      dateTime: DateTime.parse(map['dateTime']), // แปลงข้อความกลับเป็นวันที่
      note: map['note'],
    );
  }
}