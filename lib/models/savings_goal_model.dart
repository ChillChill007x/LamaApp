class SavingsGoal {
  final int? id;
  final String title;
  final String emoji;
  final double targetAmount;   // เป้าหมาย
  final double savedAmount;    // ออมได้แล้ว
  final DateTime deadline;     // วันที่อยากถึงเป้า
  final int walletId;          // กระเป๋าที่ผูกไว้
  final bool isCompleted;

  SavingsGoal({
    this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.deadline,
    required this.walletId,
    this.isCompleted = false,
  });

  double get progressRatio =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);

  // เงินที่ต้องออมต่อเดือนเพื่อให้ถึงเป้าทัน
  double get monthlyNeeded {
    final now = DateTime.now();
    final months = (deadline.year - now.year) * 12 +
        (deadline.month - now.month);
    if (months <= 0) return remaining;
    return remaining / months;
  }

  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  SavingsGoal copyWith({
    int? id,
    String? title,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    int? walletId,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      walletId: walletId ?? this.walletId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline.toIso8601String(),
    'walletId': walletId,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    id: map['id'],
    title: map['title'],
    emoji: map['emoji'] ?? '🎯',
    targetAmount: map['targetAmount'],
    savedAmount: map['savedAmount'] ?? 0,
    deadline: DateTime.parse(map['deadline']),
    walletId: map['walletId'],
    isCompleted: (map['isCompleted'] ?? 0) == 1,
  );
}
