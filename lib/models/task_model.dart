class TaskItem {
  final int? id;
  final String title;
  final DateTime deadline;
  final String status; // 'pending', 'done', 'overdue'
  final String? note;
  final DateTime createdAt;

  TaskItem({
    this.id,
    required this.title,
    required this.deadline,
    this.status = 'pending',
    this.note,
    required this.createdAt,
  });

  TaskItem copyWith({
    int? id,
    String? title,
    DateTime? deadline,
    String? status,
    String? note,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      deadline: DateTime.parse(map['deadline']),
      status: map['status'] ?? 'pending',
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // คืนค่า true ถ้างานนี้เลยกำหนดแล้วและยังไม่เสร็จ
  bool get isOverdue =>
      status == 'pending' && deadline.isBefore(DateTime.now());
}
