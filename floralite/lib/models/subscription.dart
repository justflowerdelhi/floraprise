enum SubscriptionState {
  active,
  gracePeriod,
  locked;

  String get storageValue {
    switch (this) {
      case SubscriptionState.active:
        return 'ACTIVE';
      case SubscriptionState.gracePeriod:
        return 'GRACE_PERIOD';
      case SubscriptionState.locked:
        return 'LOCKED';
    }
  }

  static SubscriptionState fromStorage(String value) {
    switch (value) {
      case 'ACTIVE':
        return SubscriptionState.active;
      case 'GRACE_PERIOD':
        return SubscriptionState.gracePeriod;
      case 'LOCKED':
        return SubscriptionState.locked;
      default:
        return SubscriptionState.locked;
    }
  }
}

enum SubscriptionPlan {
  trial,
  quarterly,
  halfYearly,
  annual;

  SubscriptionPlanConfig get config => SubscriptionPlans.byPlan(this);

  String get label => config.name;

  String get storageValue {
    switch (this) {
      case SubscriptionPlan.trial:
        return 'trial';
      case SubscriptionPlan.quarterly:
        return 'quarterly';
      case SubscriptionPlan.halfYearly:
        return 'half_yearly';
      case SubscriptionPlan.annual:
        return 'annual';
    }
  }

  static SubscriptionPlan fromStorage(String value) {
    switch (value) {
      case 'quarterly':
        return SubscriptionPlan.quarterly;
      case 'half_yearly':
        return SubscriptionPlan.halfYearly;
      case 'annual':
      case 'yearly':
        return SubscriptionPlan.annual;
      default:
        return SubscriptionPlan.trial;
    }
  }
}

class SubscriptionPlanConfig {
  const SubscriptionPlanConfig({
    required this.plan,
    required this.id,
    required this.name,
    required this.durationDays,
    required this.pricePaise,
    required this.productId,
    this.description = '',
    this.badge,
    this.recommended = false,
  });

  final SubscriptionPlan plan;
  final String id;
  final String name;
  final int durationDays;
  final int pricePaise;
  final String productId;
  final String description;
  final String? badge;
  final bool recommended;

  Duration get duration => Duration(days: durationDays);
  bool get isTrial => plan == SubscriptionPlan.trial;
  bool get isPaid => pricePaise > 0;
  String get priceLabel =>
      pricePaise == 0 ? '₹0' : '₹${(pricePaise / 100).toStringAsFixed(0)}';
}

class SubscriptionPlans {
  const SubscriptionPlans._();

  static const trial = SubscriptionPlanConfig(
    plan: SubscriptionPlan.trial,
    id: 'trial',
    name: 'Free Trial',
    durationDays: 7,
    pricePaise: 0,
    productId: 'floraprise_trial',
    description: '7 Days',
  );

  static const quarterly = SubscriptionPlanConfig(
    plan: SubscriptionPlan.quarterly,
    id: 'quarterly',
    name: 'Quarterly Plan',
    durationDays: 90,
    pricePaise: 499900,
    productId: 'floraprise_quarterly',
    description: '90 Days',
  );

  static const halfYearly = SubscriptionPlanConfig(
    plan: SubscriptionPlan.halfYearly,
    id: 'half_yearly',
    name: 'Half Yearly Plan',
    durationDays: 180,
    pricePaise: 899900,
    productId: 'floraprise_half_yearly',
    description: '180 Days',
  );

  static const annual = SubscriptionPlanConfig(
    plan: SubscriptionPlan.annual,
    id: 'annual',
    name: 'Annual Plan',
    durationDays: 365,
    pricePaise: 1499900,
    productId: 'floraprise_annual',
    description: '365 Days',
    badge: '⭐ MOST POPULAR',
    recommended: true,
  );

  static const all = [trial, quarterly, halfYearly, annual];
  static const paid = [quarterly, halfYearly, annual];

  static SubscriptionPlanConfig byPlan(SubscriptionPlan plan) {
    return all.firstWhere((config) => config.plan == plan);
  }

  static SubscriptionPlanConfig? byProductId(String productId) {
    for (final config in paid) {
      if (config.productId == productId) return config;
    }
    return null;
  }
}

class SubscriptionRecord {
  const SubscriptionRecord({
    required this.status,
    required this.plan,
    required this.expiryDate,
    required this.graceEndDate,
    required this.lastVerification,
    required this.offlineExpiry,
    required this.lastAppVersion,
    this.purchaseToken,
  });

  final SubscriptionState status;
  final SubscriptionPlan plan;
  final DateTime expiryDate;
  final DateTime graceEndDate;
  final DateTime lastVerification;
  final DateTime offlineExpiry;
  final String lastAppVersion;
  final String? purchaseToken;

  SubscriptionRecord copyWith({
    SubscriptionState? status,
    SubscriptionPlan? plan,
    DateTime? expiryDate,
    DateTime? graceEndDate,
    DateTime? lastVerification,
    DateTime? offlineExpiry,
    String? lastAppVersion,
    String? purchaseToken,
  }) {
    return SubscriptionRecord(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      expiryDate: expiryDate ?? this.expiryDate,
      graceEndDate: graceEndDate ?? this.graceEndDate,
      lastVerification: lastVerification ?? this.lastVerification,
      offlineExpiry: offlineExpiry ?? this.offlineExpiry,
      lastAppVersion: lastAppVersion ?? this.lastAppVersion,
      purchaseToken: purchaseToken ?? this.purchaseToken,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'status': status.storageValue,
      'plan': plan.storageValue,
      'purchase_token': purchaseToken,
      'expiry_date': expiryDate.toIso8601String(),
      'grace_end_date': graceEndDate.toIso8601String(),
      'last_verification': lastVerification.toIso8601String(),
      'offline_expiry': offlineExpiry.toIso8601String(),
      'last_app_version': lastAppVersion,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory SubscriptionRecord.fromMap(Map<String, Object?> map) {
    return SubscriptionRecord(
      status: SubscriptionState.fromStorage(map['status'] as String? ?? ''),
      plan: SubscriptionPlan.fromStorage(map['plan'] as String? ?? ''),
      purchaseToken: map['purchase_token'] as String?,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      graceEndDate: DateTime.parse(map['grace_end_date'] as String),
      lastVerification: DateTime.parse(map['last_verification'] as String),
      offlineExpiry: DateTime.parse(map['offline_expiry'] as String),
      lastAppVersion: map['last_app_version'] as String? ?? '1.0.0',
    );
  }
}

class SubscriptionAccess {
  const SubscriptionAccess({
    required this.record,
    required this.state,
    required this.requiresInternet,
    required this.clockTamperingDetected,
  });

  final SubscriptionRecord record;
  final SubscriptionState state;
  final bool requiresInternet;
  final bool clockTamperingDetected;

  bool get isLocked => state == SubscriptionState.locked;
  bool get isGrace => state == SubscriptionState.gracePeriod;
  bool get blocksBusinessAccess => isLocked;

  int daysRemaining(DateTime now) {
    final end = state == SubscriptionState.gracePeriod
        ? record.graceEndDate
        : record.expiryDate;
    final remaining = end.difference(DateTime(now.year, now.month, now.day));
    if (remaining.isNegative) return 0;
    return remaining.inDays;
  }

  bool get isTrial => record.plan == SubscriptionPlan.trial;

  String expiryReminder(DateTime now) {
    final days = daysRemaining(now);
    if (isTrial) {
      if (days <= 0) {
        return 'Your Free Trial Has Expired';
      }
      if (days <= 3) {
        return 'Trial expires in $days days. Upgrade now to continue uninterrupted.';
      }
      if (days <= 7) {
        return 'Trial expires in $days days. Upgrade now to continue uninterrupted.';
      }
      return '$days Days Remaining';
    }
    if (days <= 0) return 'Subscription Expired';
    if (days <= 3) {
      return 'Critical warning: subscription expires in $days days.';
    }
    if (days <= 7) return 'Subscription expires in $days days.';
    if (days <= 15) return 'Renew now to avoid interruption.';
    if (days <= 30) {
      return 'Your Floraprise subscription expires in $days days.';
    }
    return '$days Days Remaining';
  }
}

class LicenseVerificationResult {
  const LicenseVerificationResult.active({
    required this.plan,
    required this.expiryDate,
    required this.purchaseToken,
  })  : expired = false,
        verified = true;

  const LicenseVerificationResult.expired({
    required this.plan,
    required this.expiryDate,
    required this.purchaseToken,
  })  : expired = true,
        verified = true;

  const LicenseVerificationResult.unverified()
      : verified = false,
        expired = false,
        plan = SubscriptionPlan.trial,
        expiryDate = null,
        purchaseToken = null;

  final bool verified;
  final bool expired;
  final SubscriptionPlan plan;
  final DateTime? expiryDate;
  final String? purchaseToken;
}
