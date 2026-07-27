import 'walk_in_enums.dart';

class PaymentSplit {
  final PaymentMethod method;
  final int amountPaise;
  final String? reference;
  final String? methodCode;

  const PaymentSplit({
    required this.method,
    required this.amountPaise,
    this.reference,
    this.methodCode,
  });

  String get persistenceMethod => methodCode ?? method.name;

  bool get isCreditOutstanding => persistenceMethod.toLowerCase() == 'credit';
}
