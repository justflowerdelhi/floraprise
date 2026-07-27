import 'package:flutter/foundation.dart';

enum BusinessDataChangeSource {
  sale,
  expense,
  purchase,
  production,
  wastage,
  customer,
  supplier,
  scheduler,
  inventory,
  product,
  attendance,
}

class BusinessDataChanged {
  const BusinessDataChanged({
    required this.source,
    required this.occurredAt,
    this.message,
  });

  final BusinessDataChangeSource source;
  final DateTime occurredAt;
  final String? message;
}

class BusinessDataEventBus extends ChangeNotifier {
  BusinessDataChanged? _lastChange;

  BusinessDataChanged? get lastChange => _lastChange;

  void publish({
    required BusinessDataChangeSource source,
    String? message,
  }) {
    _lastChange = BusinessDataChanged(
      source: source,
      occurredAt: DateTime.now(),
      message: message,
    );
    notifyListeners();
  }
}
