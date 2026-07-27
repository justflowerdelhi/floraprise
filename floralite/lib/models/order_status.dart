import 'package:flutter/material.dart';

/// Locked Floraprise order lifecycle statuses.
///
/// Draft -> Confirmed -> Sent to Designer -> Preparing -> Ready -> Out for Delivery
/// -> Delivered | Delivery Failed | Cancelled.
class OrderStatus {
  static const String draft = 'draft';
  static const String created = 'created';
  static const String confirmed = 'confirmed';
  static const String sentToDesigner = 'sent_to_designer';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String deliveryFailed = 'delivery_failed';
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    draft,
    created,
    confirmed,
    sentToDesigner,
    preparing,
    ready,
    outForDelivery,
    delivered,
    deliveryFailed,
    cancelled,
  ];

  static const List<String> terminalStatuses = [
    delivered,
    deliveryFailed,
    cancelled,
  ];

  static const Map<String, List<String>> allowedTransitions = {
    draft: [confirmed, cancelled],
    created: [confirmed, cancelled],
    confirmed: [sentToDesigner, cancelled],
    sentToDesigner: [preparing, cancelled],
    preparing: [ready, cancelled],
    ready: [outForDelivery, cancelled],
    outForDelivery: [delivered, deliveryFailed, cancelled],
    deliveryFailed: [outForDelivery, cancelled],
  };

  static bool canTransition(String fromStatus, String toStatus) {
    final allowed = allowedTransitions[fromStatus] ?? [];
    return allowed.contains(toStatus);
  }

  static List<String> nextStatuses(String currentStatus) {
    return List.unmodifiable(allowedTransitions[currentStatus] ?? []);
  }

  static bool isTerminal(String status) {
    return terminalStatuses.contains(status);
  }

  static bool canCancel(String status) {
    return !isTerminal(status);
  }

  static String label(String status) {
    return switch (status) {
      draft => 'Draft',
      created => 'Created',
      confirmed => 'Confirmed',
      sentToDesigner => 'Sent to Designer',
      preparing => 'Preparing',
      ready => 'Ready',
      outForDelivery => 'Out for Delivery',
      delivered => 'Delivered',
      deliveryFailed => 'Delivery Failed',
      cancelled => 'Cancelled',
      _ => status.replaceAll('_', ' ').titleCase,
    };
  }

  static Color color(String status) {
    return switch (status) {
      draft => Colors.grey,
      created => Colors.blueGrey,
      confirmed => Colors.indigo,
      sentToDesigner => Colors.purple,
      preparing => Colors.orange,
      ready => Colors.green,
      outForDelivery => Colors.deepPurple,
      delivered => Colors.teal,
      deliveryFailed => Colors.red,
      cancelled => Colors.redAccent,
      _ => Colors.black54,
    };
  }

  static String actionLabel(String status) {
    return switch (status) {
      sentToDesigner => 'Send to Designer',
      preparing => 'Start Preparing',
      ready => 'Mark as Ready',
      outForDelivery => 'Out for Delivery',
      delivered => 'Mark as Delivered',
      deliveryFailed => 'Mark Delivery Failed',
      cancelled => 'Cancel Order',
      _ => 'Update Status',
    };
  }

  static String actionNote(String currentStatus, String newStatus) {
    return switch (newStatus) {
      sentToDesigner => 'Order forwarded to designer',
      preparing => 'Production started',
      ready => 'Order prepared and ready',
      outForDelivery => 'Order out for delivery',
      delivered => 'Order delivered successfully',
      deliveryFailed => 'Delivery failed',
      cancelled => 'Order cancelled',
      _ => 'Status updated from ${label(currentStatus)} to ${label(newStatus)}',
    };
  }
}

extension _StringTitleCase on String {
  String get titleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
