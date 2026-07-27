class DayClosing {
  final int id;
  final DateTime date;
  final int cashSales;
  final int upiSales;
  final int cardSales;
  final int creditSales;
  final int cashExpenses;
  final int upiExpenses;
  final int cardExpenses;
  final int openingCash;
  final int expectedCash;
  final int countedCash;
  final int difference;
  final String? notes;
  final DateTime closedAt;
  final DateTime createdAt;

  const DayClosing({
    required this.id,
    required this.date,
    required this.cashSales,
    required this.upiSales,
    required this.cardSales,
    required this.creditSales,
    required this.cashExpenses,
    required this.upiExpenses,
    required this.cardExpenses,
    required this.openingCash,
    required this.expectedCash,
    required this.countedCash,
    required this.difference,
    this.notes,
    required this.closedAt,
    required this.createdAt,
  });

  factory DayClosing.fromMap(Map<String, dynamic> map) {
    return DayClosing(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      cashSales: map['cash_sales'] as int,
      upiSales: map['upi_sales'] as int,
      cardSales: map['card_sales'] as int,
      creditSales: map['credit_sales'] as int,
      cashExpenses: map['cash_expenses'] as int,
      upiExpenses: map['upi_expenses'] as int,
      cardExpenses: map['card_expenses'] as int,
      openingCash: map['opening_cash'] as int,
      expectedCash: map['expected_cash'] as int,
      countedCash: map['counted_cash'] as int,
      difference: map['difference'] as int,
      notes: map['notes'] as String?,
      closedAt: DateTime.parse(map['closed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'cash_sales': cashSales,
      'upi_sales': upiSales,
      'card_sales': cardSales,
      'credit_sales': creditSales,
      'cash_expenses': cashExpenses,
      'upi_expenses': upiExpenses,
      'card_expenses': cardExpenses,
      'opening_cash': openingCash,
      'expected_cash': expectedCash,
      'counted_cash': countedCash,
      'difference': difference,
      'notes': notes,
      'closed_at': closedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DayClosing copyWith({
    int? id,
    DateTime? date,
    int? cashSales,
    int? upiSales,
    int? cardSales,
    int? creditSales,
    int? cashExpenses,
    int? upiExpenses,
    int? cardExpenses,
    int? openingCash,
    int? expectedCash,
    int? countedCash,
    int? difference,
    String? notes,
    DateTime? closedAt,
    DateTime? createdAt,
  }) {
    return DayClosing(
      id: id ?? this.id,
      date: date ?? this.date,
      cashSales: cashSales ?? this.cashSales,
      upiSales: upiSales ?? this.upiSales,
      cardSales: cardSales ?? this.cardSales,
      creditSales: creditSales ?? this.creditSales,
      cashExpenses: cashExpenses ?? this.cashExpenses,
      upiExpenses: upiExpenses ?? this.upiExpenses,
      cardExpenses: cardExpenses ?? this.cardExpenses,
      openingCash: openingCash ?? this.openingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      countedCash: countedCash ?? this.countedCash,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
