enum PaymentMode {
  cash,
  upi,
  card,
}

extension PaymentModeExtension on PaymentMode {
  String get displayName => switch (this) {
        PaymentMode.cash => 'Cash',
        PaymentMode.upi => 'UPI',
        PaymentMode.card => 'Card',
      };

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }
}

class Expense {
  final int id;
  final int amount;
  final int categoryId;
  final PaymentMode paymentMode;
  final String? notes;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.paymentMode,
    this.notes,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int,
      amount: map['amount'] as int,
      categoryId: map['category_id'] as int,
      paymentMode: PaymentModeExtension.fromString(map['payment_mode'] as String),
      notes: map['notes'] as String?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'payment_mode': paymentMode.name,
      'notes': notes,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Expense copyWith({
    int? id,
    int? amount,
    int? categoryId,
    PaymentMode? paymentMode,
    String? notes,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
