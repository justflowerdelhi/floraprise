class CloudOrderFulfillmentCounts {
  final int delivery;
  final int pickup;
  final int takeAway;

  const CloudOrderFulfillmentCounts({
    this.delivery = 0,
    this.pickup = 0,
    this.takeAway = 0,
  });

  factory CloudOrderFulfillmentCounts.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys) {
      for (final key in keys) {
        final val = json[key];
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) {
          final parsed = int.tryParse(val.trim());
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    return CloudOrderFulfillmentCounts(
      delivery: readInt(['delivery', 'Delivery']),
      pickup: readInt(['pickup', 'Pickup', 'pickupLater', 'pickup_later']),
      takeAway: readInt(['takeAway', 'TakeAway', 'take_away', 'takeaway']),
    );
  }

  Map<String, dynamic> toJson() => {
        'delivery': delivery,
        'pickup': pickup,
        'takeAway': takeAway,
      };
}

class CloudOrderStatusReport {
  final int pending;
  final int inProgress;
  final int ready;
  final int completed;
  final int cancelled;
  final int total;
  final CloudOrderFulfillmentCounts fulfillment;
  final DateTime? fromDate;
  final DateTime? toDate;

  const CloudOrderStatusReport({
    this.pending = 0,
    this.inProgress = 0,
    this.ready = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.total = 0,
    this.fulfillment = const CloudOrderFulfillmentCounts(),
    this.fromDate,
    this.toDate,
  });

  factory CloudOrderStatusReport.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys) {
      for (final key in keys) {
        final val = json[key];
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) {
          final parsed = int.tryParse(val.trim());
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    DateTime? readDateTime(List<String> keys) {
      for (final key in keys) {
        final val = json[key];
        if (val is String && val.trim().isNotEmpty) {
          try {
            return DateTime.parse(val);
          } catch (_) {}
        }
      }
      return null;
    }

    final rawFulfillment = json['fulfillment'] ?? json['Fulfillment'];
    final fulfillmentMap = rawFulfillment is Map<String, dynamic>
        ? rawFulfillment
        : (rawFulfillment is Map
            ? rawFulfillment.cast<String, dynamic>()
            : const <String, dynamic>{});

    return CloudOrderStatusReport(
      pending: readInt(['pending', 'Pending']),
      inProgress: readInt(['inProgress', 'InProgress', 'in_progress']),
      ready: readInt(['ready', 'Ready']),
      completed: readInt(['completed', 'Completed']),
      cancelled: readInt(['cancelled', 'Cancelled']),
      total: readInt(['total', 'Total', 'totalCount']),
      fulfillment: CloudOrderFulfillmentCounts.fromJson(fulfillmentMap),
      fromDate: readDateTime(['fromDate', 'FromDate']),
      toDate: readDateTime(['toDate', 'ToDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'pending': pending,
        'inProgress': inProgress,
        'ready': ready,
        'completed': completed,
        'cancelled': cancelled,
        'total': total,
        'fulfillment': fulfillment.toJson(),
        if (fromDate != null) 'fromDate': fromDate!.toIso8601String(),
        if (toDate != null) 'toDate': toDate!.toIso8601String(),
      };

  static const empty = CloudOrderStatusReport();
}
