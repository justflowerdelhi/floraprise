enum PaymentType {
  saleTender,
  creditCollection,
  adjustment;

  String get wireName {
    switch (this) {
      case PaymentType.saleTender:
        return 'SaleTender';
      case PaymentType.creditCollection:
        return 'CreditCollection';
      case PaymentType.adjustment:
        return 'Adjustment';
    }
  }

  static PaymentType fromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return PaymentType.saleTender;
    }
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'creditcollection':
      case 'credit_collection':
      case 'collection':
        return PaymentType.creditCollection;
      case 'adjustment':
        return PaymentType.adjustment;
      case 'saletender':
      case 'sale_tender':
      case 'sale':
      default:
        return PaymentType.saleTender;
    }
  }
}
