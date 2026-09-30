import 'dart:math';
import 'package:flutter/foundation.dart';

/// Generates a v4 UUID string for offline idempotency and sync.
String generateClientSyncId() {
  final random = Random.secure();
  final values = List<int>.generate(16, (_) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40;
  values[8] = (values[8] & 0x3f) | 0x80;
  final hex = values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Represents an actionable follow-up task on the CRM Today dashboard.
/// In Phase 1 & 2A, source must be either 'occasion' or 'scheduler' (no payment follow-ups).
@immutable
class CrmFollowUpItem {
  const CrmFollowUpItem({
    required this.id,
    required this.sourceType,
    this.localSourceId,
    this.cloudSourceId,
    required this.scheduledTime,
    required this.customerName,
    required this.customerPhone,
    required this.requirementSummary,
    this.amount,
    required this.status,
    this.isCompleted = false,
    this.customerId,
    this.cloudCustomerId,
    this.orderId,
  });

  final String id;
  /// Must be 'occasion' or 'scheduler'
  final String sourceType;
  final int? localSourceId;
  final String? cloudSourceId;
  final DateTime scheduledTime;
  final String customerName;
  final String customerPhone;
  final String requirementSummary;
  final double? amount;
  final String status;
  final bool isCompleted;
  final int? customerId;
  final String? cloudCustomerId;
  final int? orderId;

  CrmFollowUpItem copyWith({
    String? id,
    String? sourceType,
    int? localSourceId,
    String? cloudSourceId,
    DateTime? scheduledTime,
    String? customerName,
    String? customerPhone,
    String? requirementSummary,
    double? amount,
    String? status,
    bool? isCompleted,
    int? customerId,
    String? cloudCustomerId,
    int? orderId,
  }) {
    return CrmFollowUpItem(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      localSourceId: localSourceId ?? this.localSourceId,
      cloudSourceId: cloudSourceId ?? this.cloudSourceId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      requirementSummary: requirementSummary ?? this.requirementSummary,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      customerId: customerId ?? this.customerId,
      cloudCustomerId: cloudCustomerId ?? this.cloudCustomerId,
      orderId: orderId ?? this.orderId,
    );
  }
}

/// Persistent Enquiry entity and view model in CRM Phase 2A.
/// Supports Solo SQLite, Cloud Mobile, and Floraprise Web.
@immutable
class CrmEnquiryItem {
  static const List<String> validStatuses = [
    'new',
    'follow_up',
    'quote_sent',
    'won',
    'lost',
  ];

  CrmEnquiryItem({
    this.localId,
    this.cloudId,
    String? id,
    String? clientSyncId,
    this.customerId,
    this.cloudCustomerId,
    required this.customerName,
    required this.customerPhone,
    this.category = 'General',
    required this.requirement,
    this.eventDate,
    int? budgetPaise,
    double? budget,
    this.location,
    this.notes,
    this.status = 'new',
    this.nextAction = 'Follow-up with customer',
    this.nextFollowUpAt,
    this.quoteOrderId,
    this.convertedOrderId,
    this.lostReason,
    required this.createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : clientSyncId = clientSyncId ?? (id ?? ''),
        budgetPaise = budgetPaise ?? (budget != null ? (budget * 100).round() : null),
        updatedAt = updatedAt ?? createdAt;

  final int? localId;
  final String? cloudId;
  final String clientSyncId;
  final int? customerId;
  final String? cloudCustomerId;
  final String customerName;
  final String customerPhone;
  final String category;
  final String requirement;
  final DateTime? eventDate;
  final int? budgetPaise;
  final String? location;
  final String? notes;
  final String status;
  final String nextAction;
  final DateTime? nextFollowUpAt;
  final int? quoteOrderId;
  final int? convertedOrderId;
  final String? lostReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  String get id => cloudId ?? (localId != null ? localId.toString() : clientSyncId);

  double? get budgetAmount => budgetPaise != null ? budgetPaise! / 100.0 : null;
  double? get budget => budgetAmount;

  CrmEnquiryItem copyWith({
    int? localId,
    String? cloudId,
    String? clientSyncId,
    int? customerId,
    String? cloudCustomerId,
    String? customerName,
    String? customerPhone,
    String? category,
    String? requirement,
    DateTime? eventDate,
    int? budgetPaise,
    String? location,
    String? notes,
    String? status,
    String? nextAction,
    DateTime? nextFollowUpAt,
    int? quoteOrderId,
    int? convertedOrderId,
    String? lostReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CrmEnquiryItem(
      localId: localId ?? this.localId,
      cloudId: cloudId ?? this.cloudId,
      clientSyncId: clientSyncId ?? this.clientSyncId,
      customerId: customerId ?? this.customerId,
      cloudCustomerId: cloudCustomerId ?? this.cloudCustomerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      category: category ?? this.category,
      requirement: requirement ?? this.requirement,
      eventDate: eventDate ?? this.eventDate,
      budgetPaise: budgetPaise ?? this.budgetPaise,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      nextAction: nextAction ?? this.nextAction,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      quoteOrderId: quoteOrderId ?? this.quoteOrderId,
      convertedOrderId: convertedOrderId ?? this.convertedOrderId,
      lostReason: lostReason ?? this.lostReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory CrmEnquiryItem.fromSqlite(Map<String, dynamic> map) {
    return CrmEnquiryItem(
      localId: map['id'] as int?,
      cloudId: map['cloud_id'] as String?,
      clientSyncId: (map['client_sync_id'] as String?) ?? '',
      customerId: map['customer_id'] as int?,
      cloudCustomerId: map['cloud_customer_id'] as String?,
      customerName: (map['customer_name'] as String?) ?? '',
      customerPhone: (map['customer_phone'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      requirement: (map['requirement'] as String?) ?? '',
      eventDate: map['event_date'] != null ? DateTime.tryParse(map['event_date'] as String) : null,
      budgetPaise: map['budget_paise'] as int?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      status: (map['status'] as String?) ?? 'new',
      nextAction: (map['next_action'] as String?) ?? 'Follow-up with customer',
      nextFollowUpAt: map['next_follow_up_at'] != null ? DateTime.tryParse(map['next_follow_up_at'] as String) : null,
      quoteOrderId: map['quote_order_id'] as int?,
      convertedOrderId: map['converted_order_id'] as int?,
      lostReason: map['lost_reason'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      if (localId != null) 'id': localId,
      'cloud_id': cloudId,
      'client_sync_id': clientSyncId,
      'customer_id': customerId,
      'cloud_customer_id': cloudCustomerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'category': category,
      'requirement': requirement,
      'event_date': eventDate?.toIso8601String(),
      'budget_paise': budgetPaise,
      'location': location,
      'notes': notes,
      'status': status,
      'next_action': nextAction,
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'quote_order_id': quoteOrderId,
      'converted_order_id': convertedOrderId,
      'lost_reason': lostReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory CrmEnquiryItem.fromCloudJson(Map<String, dynamic> json) {
    return CrmEnquiryItem(
      cloudId: json['id']?.toString() ?? json['Id']?.toString(),
      clientSyncId: (json['clientSyncId'] ?? json['ClientSyncId'] ?? '').toString(),
      cloudCustomerId: json['customerId']?.toString() ?? json['CustomerId']?.toString(),
      customerName: (json['customerName'] ?? json['CustomerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? json['CustomerPhone'] ?? '').toString(),
      category: (json['category'] ?? json['Category'] ?? 'General').toString(),
      requirement: (json['requirement'] ?? json['Requirement'] ?? '').toString(),
      eventDate: _parseDateTime(json['eventDate'] ?? json['EventDate']),
      budgetPaise: _parseBudgetPaise(json['budgetAmount'] ?? json['BudgetAmount']),
      location: json['location']?.toString() ?? json['Location']?.toString(),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'new').toString(),
      nextAction: (json['nextAction'] ?? json['NextAction'] ?? 'Follow-up with customer').toString(),
      nextFollowUpAt: _parseDateTime(json['nextFollowUpAt'] ?? json['NextFollowUpAt']),
      quoteOrderId: _parseInt(json['quoteOrderId'] ?? json['QuoteOrderId']),
      convertedOrderId: _parseInt(json['convertedOrderId'] ?? json['ConvertedOrderId']),
      lostReason: json['lostReason']?.toString() ?? json['LostReason']?.toString(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['UpdatedAt']) ?? DateTime.now(),
      deletedAt: _parseDateTime(json['deletedAt'] ?? json['DeletedAt']),
    );
  }

  Map<String, dynamic> toCloudJson() {
    return {
      'clientSyncId': clientSyncId,
      'customerId': cloudCustomerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'category': category,
      'requirement': requirement,
      'eventDate': eventDate?.toUtc().toIso8601String(),
      'budgetAmount': budgetPaise != null ? (budgetPaise! / 100.0) : null,
      'location': location,
      'notes': notes,
      'status': status,
      'nextAction': nextAction,
      'nextFollowUpAt': nextFollowUpAt?.toUtc().toIso8601String(),
      'quoteOrderId': quoteOrderId,
      'convertedOrderId': convertedOrderId,
      'lostReason': lostReason,
    };
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  static int? _parseBudgetPaise(dynamic val) {
    if (val == null) return null;
    if (val is num) return (val * 100).round();
    final parsed = double.tryParse(val.toString());
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }
}

/// Represents a pending quotation / draft order on the CRM Today dashboard.
@immutable
class CrmQuoteItem {
  const CrmQuoteItem({
    required this.id,
    this.orderId,
    this.cloudOrderId,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.requirementSummary,
    required this.amount,
    required this.date,
    required this.nextAction,
  });

  final String id;
  final int? orderId;
  final String? cloudOrderId;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final String requirementSummary;
  final double amount;
  final DateTime date;
  final String nextAction;
}

/// Represents an upcoming customer occasion for the current week.
@immutable
class CrmOccasionItem {
  const CrmOccasionItem({
    required this.id,
    required this.customerName,
    required this.recipientName,
    required this.customerPhone,
    required this.occasion,
    required this.relationship,
    required this.occasionDate,
    required this.dayLabel,
    this.notes = '',
    this.customerId,
    this.cloudCustomerId,
  });

  final String id;
  final String customerName;
  final String recipientName;
  final String customerPhone;
  final String occasion;
  final String relationship;
  final DateTime occasionDate;
  final String dayLabel;
  final String notes;
  final int? customerId;
  final String? cloudCustomerId;
}

/// Unified container for CRM Today Dashboard data.
@immutable
class CrmTodayData {
  const CrmTodayData({
    required this.followUps,
    required this.enquiries,
    required this.pendingQuotes,
    required this.upcomingOccasions,
    required this.evaluatedAt,
  });

  final List<CrmFollowUpItem> followUps;
  final List<CrmEnquiryItem> enquiries;
  final List<CrmQuoteItem> pendingQuotes;
  final List<CrmOccasionItem> upcomingOccasions;
  final DateTime evaluatedAt;

  static final empty = CrmTodayData(
    followUps: const [],
    enquiries: const [],
    pendingQuotes: const [],
    upcomingOccasions: const [],
    evaluatedAt: DateTime.now(),
  );

  int get pendingFollowUpsCount =>
      followUps.where((f) => !f.isCompleted).length;
}
