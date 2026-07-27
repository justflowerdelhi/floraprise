class OpeningCash {
  final int id;
  final DateTime date;
  final int amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpeningCash({
    required this.id,
    required this.date,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpeningCash.fromMap(Map<String, dynamic> map) {
    return OpeningCash(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      amount: map['amount'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OpeningCash copyWith({
    int? id,
    DateTime? date,
    int? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpeningCash(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
