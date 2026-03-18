class Wallet {
  final int? id;
  final String name;
  final String emojiIcon;
  final double initialBalance;
  String? note;

  // ─── Budget fields ────────────────────────────────────
  // งบประมาณรายจ่ายต่อเดือน (null = ไม่ได้ตั้ง)
  final double? monthlyBudget;

  // แจ้งเตือนเมื่อใช้ไปถึง % นี้ (เช่น 80.0 = 80%)
  final double? alertPercent;

  // แจ้งเตือนเมื่อยอดคงเหลือต่ำกว่านี้ (null = ไม่ได้ตั้ง)
  final double? lowBalanceThreshold;

  Wallet({
    this.id,
    required this.name,
    required this.emojiIcon,
    required this.initialBalance,
    this.note,
    this.monthlyBudget,
    this.alertPercent,
    this.lowBalanceThreshold,
  });

  Wallet copyWith({
    int? id,
    String? name,
    String? emojiIcon,
    double? initialBalance,
    String? note,
    double? monthlyBudget,
    double? alertPercent,
    double? lowBalanceThreshold,
    // ใช้ sentinel เพื่อรองรับการ set ค่า null ได้จริง
    bool clearMonthlyBudget = false,
    bool clearAlertPercent = false,
    bool clearLowBalance = false,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      emojiIcon: emojiIcon ?? this.emojiIcon,
      initialBalance: initialBalance ?? this.initialBalance,
      note: note ?? this.note,
      monthlyBudget:
          clearMonthlyBudget ? null : (monthlyBudget ?? this.monthlyBudget),
      alertPercent:
          clearAlertPercent ? null : (alertPercent ?? this.alertPercent),
      lowBalanceThreshold: clearLowBalance
          ? null
          : (lowBalanceThreshold ?? this.lowBalanceThreshold),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emojiIcon': emojiIcon,
      'initialBalance': initialBalance,
      'note': note,
      'monthlyBudget': monthlyBudget,
      'alertPercent': alertPercent,
      'lowBalanceThreshold': lowBalanceThreshold,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      emojiIcon: map['emojiIcon'],
      initialBalance: map['initialBalance'],
      note: map['note'],
      monthlyBudget: map['monthlyBudget'],
      alertPercent: map['alertPercent'],
      lowBalanceThreshold: map['lowBalanceThreshold'],
    );
  }
}
