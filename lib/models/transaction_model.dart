class TransactionItem {
  final int? id;
  final int walletId;
  final String type;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String? note;
  final String? imagePath; // ✅ path รูปสลิปที่แนบ

  TransactionItem({
    this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.note,
    this.imagePath,
  });

  TransactionItem copyWith({
    int? id,
    int? walletId,
    String? type,
    double? amount,
    String? category,
    DateTime? dateTime,
    String? note,
    String? imagePath,
    bool clearImage = false,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'walletId': walletId,
    'type': type,
    'amount': amount,
    'category': category,
    'dateTime': dateTime.toIso8601String(),
    'note': note,
    'imagePath': imagePath,
  };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
    id: map['id'],
    walletId: map['walletId'],
    type: map['type'],
    amount: map['amount'],
    category: map['category'],
    dateTime: DateTime.parse(map['dateTime']),
    note: map['note'],
    imagePath: map['imagePath'],
  );
}
