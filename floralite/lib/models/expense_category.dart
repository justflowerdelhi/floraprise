class ExpenseCategory {
  final int id;
  final String name;
  final String emoji;
  final String groupName;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groupName,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      groupName: map['group_name'] as String,
      active: (map['active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'group_name': groupName,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? emoji,
    String? groupName,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      groupName: groupName ?? this.groupName,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
