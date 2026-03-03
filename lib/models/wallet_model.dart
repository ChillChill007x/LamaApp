class Wallet {
  final int? id;
  final String name;
  final String emojiIcon; 
  final double initialBalance;
  String? note;

  Wallet({
    this.id,
    required this.name,
    required this.emojiIcon,
    required this.initialBalance,
    this.note,
  });

  Wallet copyWith({
    int? id,
    String? name,
    String? emojiIcon,
    double? initialBalance,
    String? note,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      emojiIcon: emojiIcon ?? this.emojiIcon,
      initialBalance: initialBalance ?? this.initialBalance,
      note: note ?? this.note,
    );
  }

  // ฟังก์ชันแปลงข้อมูลเป็น Map เพื่อนำไปบันทึกลงฐานข้อมูล SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emojiIcon': emojiIcon,
      'initialBalance': initialBalance,
      'note': note,
    };
  }

  // ฟังก์ชันสร้าง Object Wallet จากข้อมูล Map ที่ดึงมาจาก SQLite
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      emojiIcon: map['emojiIcon'],
      initialBalance: map['initialBalance'],
      note: map['note'],
    );
  }
}