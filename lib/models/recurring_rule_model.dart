enum RecurringFrequency { daily, weekly, monthly }

class RecurringRule {
  final int? id;
  final int walletId;
  final String label;
  final double amount;
  final String category;
  final String frequency;  // 'daily' | 'weekly' | 'monthly'
  final int dayValue;      // monthly=วันที่, weekly=weekday(1-7), daily=0
  final bool isActive;
  final DateTime? lastRunAt;
  final String txType;     // ✅ 'income' | 'expense'

  RecurringRule({
    this.id,
    required this.walletId,
    required this.label,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.dayValue,
    this.isActive = true,
    this.lastRunAt,
    this.txType = 'income',
  });

  bool get isExpense => txType == 'expense';

  RecurringFrequency get frequencyEnum {
    switch (frequency) {
      case 'daily':  return RecurringFrequency.daily;
      case 'weekly': return RecurringFrequency.weekly;
      default:       return RecurringFrequency.monthly;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':   return 'ทุกวัน';
      case 'weekly':  return 'ทุก${_weekdayName(dayValue)}';
      default:        return 'ทุกวันที่ $dayValue';
    }
  }

  static String _weekdayName(int d) {
    const n = {1:'จันทร์',2:'อังคาร',3:'พุธ',4:'พฤหัส',5:'ศุกร์',6:'เสาร์',7:'อาทิตย์'};
    return n[d] ?? '$d';
  }

  RecurringRule copyWith({
    int? id, int? walletId, String? label, double? amount,
    String? category, String? frequency, int? dayValue,
    bool? isActive, DateTime? lastRunAt, String? txType,
    bool clearLastRun = false,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      dayValue: dayValue ?? this.dayValue,
      isActive: isActive ?? this.isActive,
      lastRunAt: clearLastRun ? null : (lastRunAt ?? this.lastRunAt),
      txType: txType ?? this.txType,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'walletId': walletId,
    'label': label,
    'amount': amount,
    'category': category,
    'frequency': frequency,
    'dayValue': dayValue,
    'isActive': isActive ? 1 : 0,
    'lastRunAt': lastRunAt?.toIso8601String(),
    'txType': txType,
  };

  factory RecurringRule.fromMap(Map<String, dynamic> map) => RecurringRule(
    id: map['id'],
    walletId: map['walletId'],
    label: map['label'],
    amount: map['amount'],
    category: map['category'],
    frequency: map['frequency'],
    dayValue: map['dayValue'],
    isActive: (map['isActive'] ?? 1) == 1,
    lastRunAt: map['lastRunAt'] != null ? DateTime.parse(map['lastRunAt']) : null,
    txType: map['txType'] ?? 'income',
  );
}
