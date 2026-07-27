enum CashBookTransactionType {
  cashSale,
  cashRefund,
  cashExpense,
  cashReceived,
  cashPaid,
}

extension CashBookTransactionTypeExtension on CashBookTransactionType {
  String get displayName => switch (this) {
        CashBookTransactionType.cashSale => 'Cash Sale',
        CashBookTransactionType.cashRefund => 'Cash Refund',
        CashBookTransactionType.cashExpense => 'Expense',
        CashBookTransactionType.cashReceived => 'Cash Received',
        CashBookTransactionType.cashPaid => 'Cash Paid',
      };

  static CashBookTransactionType fromString(String value) {
    return CashBookTransactionType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CashBookTransactionType.cashReceived,
    );
  }
}

class CashBook {
  final int id;
  final DateTime date;
  final CashBookTransactionType transactionType;
  final String description;
  final int amount;
  final int cashIn;
  final int cashOut;
  final int runningBalance;
  final DateTime createdAt;

  const CashBook({
    required this.id,
    required this.date,
    required this.transactionType,
    required this.description,
    required this.amount,
    required this.cashIn,
    required this.cashOut,
    required this.runningBalance,
    required this.createdAt,
  });

  factory CashBook.fromMap(Map<String, dynamic> map) {
    return CashBook(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      transactionType: CashBookTransactionTypeExtension.fromString(map['transaction_type'] as String),
      description: map['description'] as String,
      amount: map['amount'] as int,
      cashIn: map['cash_in'] as int,
      cashOut: map['cash_out'] as int,
      runningBalance: map['running_balance'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'transaction_type': transactionType.name,
      'description': description,
      'amount': amount,
      'cash_in': cashIn,
      'cash_out': cashOut,
      'running_balance': runningBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CashBook copyWith({
    int? id,
    DateTime? date,
    CashBookTransactionType? transactionType,
    String? description,
    int? amount,
    int? cashIn,
    int? cashOut,
    int? runningBalance,
    DateTime? createdAt,
  }) {
    return CashBook(
      id: id ?? this.id,
      date: date ?? this.date,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      cashIn: cashIn ?? this.cashIn,
      cashOut: cashOut ?? this.cashOut,
      runningBalance: runningBalance ?? this.runningBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
