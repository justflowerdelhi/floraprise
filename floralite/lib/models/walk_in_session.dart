import 'payment_split.dart';
import 'walk_in_enums.dart';
import 'walk_in_line_item.dart';

class WalkInSession {
  final int? draftOrderId;
  final FulfilmentType fulfilmentType;
  final List<WalkInLineItem> lines;
  final String customerPhone;
  final String customerName;
  final String occasion;
  final DateTime? scheduledAt;
  final String deliverySlot;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String deliveryPincode;
  final String deliveryLandmark;
  final String cardMessage;
  final String specialInstructions;
  final List<PaymentSplit> payments;
  final String? billDiscountType;
  final int? billDiscountValue;

  const WalkInSession({
    this.draftOrderId,
    required this.fulfilmentType,
    this.lines = const [],
    this.customerPhone = '',
    this.customerName = '',
    this.occasion = '',
    this.scheduledAt,
    this.deliverySlot = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.deliveryAddress = '',
    this.deliveryPincode = '',
    this.deliveryLandmark = '',
    this.cardMessage = '',
    this.specialInstructions = '',
    this.payments = const [],
    this.billDiscountType,
    this.billDiscountValue,
  });

  WalkInSession copyWith({
    int? draftOrderId,
    FulfilmentType? fulfilmentType,
    List<WalkInLineItem>? lines,
    String? customerPhone,
    String? customerName,
    String? occasion,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? deliverySlot,
    String? recipientName,
    String? recipientPhone,
    String? deliveryAddress,
    String? deliveryPincode,
    String? deliveryLandmark,
    String? cardMessage,
    String? specialInstructions,
    List<PaymentSplit>? payments,
    String? billDiscountType,
    int? billDiscountValue,
  }) {
    return WalkInSession(
      draftOrderId: draftOrderId ?? this.draftOrderId,
      fulfilmentType: fulfilmentType ?? this.fulfilmentType,
      lines: lines ?? this.lines,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName ?? this.customerName,
      occasion: occasion ?? this.occasion,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      deliverySlot: deliverySlot ?? this.deliverySlot,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPincode: deliveryPincode ?? this.deliveryPincode,
      deliveryLandmark: deliveryLandmark ?? this.deliveryLandmark,
      cardMessage: cardMessage ?? this.cardMessage,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      payments: payments ?? this.payments,
      billDiscountType: billDiscountType ?? this.billDiscountType,
      billDiscountValue: billDiscountValue ?? this.billDiscountValue,
    );
  }

  factory WalkInSession.empty(FulfilmentType type) {
    return WalkInSession(fulfilmentType: type);
  }
}
