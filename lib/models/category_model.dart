class CategoryItem {
  final int? id;
  final String name;
  final String emoji;
  final String type; // 'expense' | 'income' | 'both'
  final bool isDefault; // default categories ลบไม่ได้
  final int sortOrder;

  CategoryItem({
    this.id,
    required this.name,
    required this.emoji,
    required this.type,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  CategoryItem copyWith({
    int? id,
    String? name,
    String? emoji,
    String? type,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'type': type,
    'isDefault': isDefault ? 1 : 0,
    'sortOrder': sortOrder,
  };

  factory CategoryItem.fromMap(Map<String, dynamic> map) => CategoryItem(
    id: map['id'],
    name: map['name'],
    emoji: map['emoji'] ?? '📦',
    type: map['type'] ?? 'expense',
    isDefault: (map['isDefault'] ?? 0) == 1,
    sortOrder: map['sortOrder'] ?? 0,
  );

  // Default categories ที่ seed ตอนติดตั้งแอป
  static List<CategoryItem> get defaults => [
    // expense
    CategoryItem(name: 'อาหาร',       emoji: '🍜', type: 'expense', isDefault: true, sortOrder: 1),
    CategoryItem(name: 'ขนม',         emoji: '🧁', type: 'expense', isDefault: true, sortOrder: 2),
    CategoryItem(name: 'เดินทาง',     emoji: '🚌', type: 'expense', isDefault: true, sortOrder: 3),
    CategoryItem(name: 'ช้อปปิ้ง',   emoji: '🛍️', type: 'expense', isDefault: true, sortOrder: 4),
    CategoryItem(name: 'บันเทิง',     emoji: '🎮', type: 'expense', isDefault: true, sortOrder: 5),
    CategoryItem(name: 'ค่าน้ำมัน',  emoji: '⛽', type: 'expense', isDefault: true, sortOrder: 6),
    CategoryItem(name: 'เครื่องสำอาง',emoji: '💄', type: 'expense', isDefault: true, sortOrder: 7),
    CategoryItem(name: 'เติมเกม',     emoji: '🕹️', type: 'expense', isDefault: true, sortOrder: 8),
    CategoryItem(name: 'ค่าไฟ/น้ำ',  emoji: '💡', type: 'expense', isDefault: true, sortOrder: 9),
    CategoryItem(name: 'ค่าเช่า',    emoji: '🏠', type: 'expense', isDefault: true, sortOrder: 10),
    CategoryItem(name: 'ค่ารักษา',   emoji: '🏥', type: 'expense', isDefault: true, sortOrder: 11),
    CategoryItem(name: 'อื่นๆ',       emoji: '📦', type: 'expense', isDefault: true, sortOrder: 99),
    // income
    CategoryItem(name: 'เงินเดือน',  emoji: '💰', type: 'income', isDefault: true, sortOrder: 1),
    CategoryItem(name: 'ธุรกิจ',     emoji: '💼', type: 'income', isDefault: true, sortOrder: 2),
    CategoryItem(name: 'โบนัส',      emoji: '🎁', type: 'income', isDefault: true, sortOrder: 3),
    CategoryItem(name: 'อื่นๆ',      emoji: '📦', type: 'income', isDefault: true, sortOrder: 99),
  ];
}
