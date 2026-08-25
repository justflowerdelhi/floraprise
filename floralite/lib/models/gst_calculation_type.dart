enum GstCalculationType {
  inclusive,
  exclusive;

  static GstCalculationType fromStorage(String? value) {
    return value == exclusive.storageValue ? exclusive : inclusive;
  }

  String get storageValue {
    switch (this) {
      case GstCalculationType.inclusive:
        return 'inclusive';
      case GstCalculationType.exclusive:
        return 'exclusive';
    }
  }

  String get label {
    switch (this) {
      case GstCalculationType.inclusive:
        return 'Inclusive';
      case GstCalculationType.exclusive:
        return 'Exclusive';
    }
  }
}

class GstLineBreakup {
  const GstLineBreakup({
    required this.basicAmountPaise,
    required this.gstAmountPaise,
    required this.totalAmountPaise,
  });

  final int basicAmountPaise;
  final int gstAmountPaise;
  final int totalAmountPaise;
}

GstLineBreakup calculateGstLineBreakup({
  required int amountPaise,
  required int gstPercent,
  required GstCalculationType calculationType,
}) {
  final safeAmount = amountPaise < 0 ? 0 : amountPaise;
  final safeGst = gstPercent < 0 ? 0 : gstPercent;
  if (safeAmount == 0 || safeGst == 0) {
    return GstLineBreakup(
      basicAmountPaise: safeAmount,
      gstAmountPaise: 0,
      totalAmountPaise: safeAmount,
    );
  }

  switch (calculationType) {
    case GstCalculationType.inclusive:
      final basic = (safeAmount * 100 / (100 + safeGst)).round();
      return GstLineBreakup(
        basicAmountPaise: basic,
        gstAmountPaise: safeAmount - basic,
        totalAmountPaise: safeAmount,
      );
    case GstCalculationType.exclusive:
      final gst = (safeAmount * safeGst / 100).round();
      return GstLineBreakup(
        basicAmountPaise: safeAmount,
        gstAmountPaise: gst,
        totalAmountPaise: safeAmount + gst,
      );
  }
}
