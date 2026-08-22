import 'gst_calculation_type.dart';

class WalkInLineItem {
  final int? productId;
  final String? designRef;
  final String description;
  final int quantity;
  final int unitPricePaise;
  final int gstPercent;
  final GstCalculationType gstCalculationType;
  final int discountPaise;
  final String? discountType;
  final int? discountValue;
  final String source;

  const WalkInLineItem({
    this.productId,
    this.designRef,
    required this.description,
    required this.quantity,
    required this.unitPricePaise,
    this.gstPercent = 12,
    this.gstCalculationType = GstCalculationType.inclusive,
    this.discountPaise = 0,
    this.discountType,
    this.discountValue,
    required this.source,
  });

  WalkInLineItem copyWith({
    int? quantity,
    int? unitPricePaise,
    int? discountPaise,
    String? discountType,
    int? discountValue,
  }) {
    return WalkInLineItem(
      productId: productId,
      designRef: designRef,
      description: description,
      quantity: quantity ?? this.quantity,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      gstPercent: gstPercent,
      gstCalculationType: gstCalculationType,
      discountPaise: discountPaise ?? this.discountPaise,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      source: source,
    );
  }
}
