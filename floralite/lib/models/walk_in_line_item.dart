import 'gst_calculation_type.dart';

class WalkInLineItem {
  final int? productId;
  final String? cloudProductId;
  final String? designRef;
  final String description;
  final int quantity;
  final int unitPricePaise;
  final int? gstPercent;
  final GstCalculationType? gstCalculationType;
  final int discountPaise;
  final String? discountType;
  final int? discountValue;
  final String source;

  const WalkInLineItem({
    this.productId,
    this.cloudProductId,
    this.designRef,
    required this.description,
    required this.quantity,
    required this.unitPricePaise,
    this.gstPercent,
    this.gstCalculationType,
    this.discountPaise = 0,
    this.discountType,
    this.discountValue,
    this.source = 'manual',
  });

  WalkInLineItem copyWith({
    int? quantity,
    int? unitPricePaise,
    int? gstPercent,
    GstCalculationType? gstCalculationType,
    int? discountPaise,
    String? discountType,
    int? discountValue,
  }) {
    return WalkInLineItem(
      productId: productId,
      cloudProductId: cloudProductId,
      designRef: designRef,
      description: description,
      quantity: quantity ?? this.quantity,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      gstPercent: gstPercent ?? this.gstPercent,
      gstCalculationType: gstCalculationType ?? this.gstCalculationType,
      discountPaise: discountPaise ?? this.discountPaise,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      source: source,
    );
  }
}
