class OrderListItem {
  final int id;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final String recipientName;
  final String? designerName;
  final String? deliveryName;
  final String source;
  final String fulfilmentType;
  final String status;
  final int grandTotalPaise;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int isPaid;

  const OrderListItem({
    required this.id,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.recipientName,
    this.designerName,
    this.deliveryName,
    required this.source,
    required this.fulfilmentType,
    required this.status,
    required this.grandTotalPaise,
    required this.createdAt,
    required this.scheduledAt,
    required this.isPaid,
  });
}

class OrderTimelineItem {
  final String status;
  final String? notes;
  final DateTime createdAt;

  const OrderTimelineItem({
    required this.status,
    this.notes,
    required this.createdAt,
  });
}

class OrderDetailHeader {
  final int id;
  final String orderNo;
  final String status;
  final String customerName;
  final String customerPhone;
  final String recipientName;
  final String recipientPhone;
  final String fulfilmentType;
  final String source;
  final int grandTotalPaise;
  final String address;
  final String deliveryPincode;
  final String deliveryLandmark;
  final String specialInstructions;
  final DateTime? scheduledAt;
  final String occasion;
  final String deliverySlot;
  final String cardMessage;
  final int isPaid;
  final int paidAmountPaise;
  final int rewardPointsEarned;
  final int rewardPointsRedeemed;
  final int rewardDiscountAmountPaise;
  final String? designerName;
  final String? deliveryName;

  const OrderDetailHeader({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.recipientName,
    required this.recipientPhone,
    required this.fulfilmentType,
    required this.source,
    required this.grandTotalPaise,
    required this.address,
    this.deliveryPincode = '',
    this.deliveryLandmark = '',
    this.specialInstructions = '',
    required this.scheduledAt,
    required this.occasion,
    required this.deliverySlot,
    required this.cardMessage,
    required this.isPaid,
    required this.paidAmountPaise,
    this.rewardPointsEarned = 0,
    this.rewardPointsRedeemed = 0,
    this.rewardDiscountAmountPaise = 0,
    this.designerName,
    this.deliveryName,
  });

  int get outstandingAmountPaise =>
      (grandTotalPaise - paidAmountPaise).clamp(0, grandTotalPaise);

  String get paymentStatus => isPaid == 1
      ? 'Paid'
      : paidAmountPaise > 0
          ? 'Partial'
          : 'Pending';
}

class OrderDetailBundle {
  final OrderDetailHeader header;
  final List<Map<String, Object?>> lines;
  final List<Map<String, Object?>> payments;
  final List<OrderTimelineItem> timeline;
  final List<Map<String, Object?>> schedulerTasks;
  final List<Map<String, Object?>> inventoryTransactions;
  final String? receiptStatus;
  final String? whatsappStatus;
  final Map<String, Object?> relayInfo;
  final Map<String, Object?> corporateInfo;
  final Map<String, Object?> marketplaceInfo;

  const OrderDetailBundle({
    required this.header,
    required this.lines,
    required this.payments,
    required this.timeline,
    required this.schedulerTasks,
    required this.inventoryTransactions,
    required this.receiptStatus,
    required this.whatsappStatus,
    required this.relayInfo,
    required this.corporateInfo,
    required this.marketplaceInfo,
  });
}

class OrderRewardSummary {
  const OrderRewardSummary({
    required this.openingBalance,
    required this.earnedPoints,
    required this.redeemedPoints,
    required this.closingBalance,
    required this.rewardValuePaise,
  });

  final int openingBalance;
  final int earnedPoints;
  final int redeemedPoints;
  final int closingBalance;
  final int rewardValuePaise;

  bool get hasActivity => earnedPoints > 0 || redeemedPoints > 0;
}

class OrderWorkspaceFilters {
  final DateTime? selectedDate;
  final bool today;
  final bool pending;
  final bool completed;
  final bool cancelled;
  final bool delivery;
  final bool pickup;
  final bool takeAway;
  final bool relay;
  final bool corporate;
  final bool marketplace;
  final bool paid;
  final bool unpaid;

  const OrderWorkspaceFilters({
    this.selectedDate,
    this.today = false,
    this.pending = false,
    this.completed = false,
    this.cancelled = false,
    this.delivery = false,
    this.pickup = false,
    this.takeAway = false,
    this.relay = false,
    this.corporate = false,
    this.marketplace = false,
    this.paid = false,
    this.unpaid = false,
  });

  static const empty = OrderWorkspaceFilters();

  OrderWorkspaceFilters copyWith({
    DateTime? selectedDate,
    bool? today,
    bool? pending,
    bool? completed,
    bool? cancelled,
    bool? delivery,
    bool? pickup,
    bool? takeAway,
    bool? relay,
    bool? corporate,
    bool? marketplace,
    bool? paid,
    bool? unpaid,
    bool clearSelectedDate = false,
  }) {
    return OrderWorkspaceFilters(
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      today: today ?? this.today,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      cancelled: cancelled ?? this.cancelled,
      delivery: delivery ?? this.delivery,
      pickup: pickup ?? this.pickup,
      takeAway: takeAway ?? this.takeAway,
      relay: relay ?? this.relay,
      corporate: corporate ?? this.corporate,
      marketplace: marketplace ?? this.marketplace,
      paid: paid ?? this.paid,
      unpaid: unpaid ?? this.unpaid,
    );
  }
}
