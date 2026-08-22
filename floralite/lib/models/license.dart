enum CloudLicensePlan {
  trial,
  halfYearly,
  yearly,
}

extension CloudLicensePlanLabel on CloudLicensePlan {
  String get label {
    switch (this) {
      case CloudLicensePlan.trial:
        return 'Trial';
      case CloudLicensePlan.halfYearly:
        return 'Half-Yearly';
      case CloudLicensePlan.yearly:
        return 'Yearly';
    }
  }

  static CloudLicensePlan fromApi(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'halfyearly':
      case 'half_yearly':
      case 'half-yearly':
        return CloudLicensePlan.halfYearly;
      case 'yearly':
        return CloudLicensePlan.yearly;
      default:
        return CloudLicensePlan.trial;
    }
  }
}

enum CloudLicenseStatus {
  trial,
  active,
  expired,
  suspended,
  unregistered,
  internetRequired,
}

extension CloudLicenseStatusLabel on CloudLicenseStatus {
  String get label {
    switch (this) {
      case CloudLicenseStatus.trial:
        return 'Trial';
      case CloudLicenseStatus.active:
        return 'Active';
      case CloudLicenseStatus.expired:
        return 'Expired';
      case CloudLicenseStatus.suspended:
        return 'Suspended';
      case CloudLicenseStatus.unregistered:
        return 'Unregistered';
      case CloudLicenseStatus.internetRequired:
        return 'Internet Required';
    }
  }

  bool get allowsAccess {
    return this == CloudLicenseStatus.trial ||
        this == CloudLicenseStatus.active;
  }

  static CloudLicenseStatus fromApi(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case '1':
      case 'active':
        return CloudLicenseStatus.active;
      case '4':
      case 'expired':
        return CloudLicenseStatus.expired;
      case '2':
      case '3':
      case 'suspended':
      case 'revoked':
        return CloudLicenseStatus.suspended;
      case 'trial':
        return CloudLicenseStatus.trial;
      default:
        return CloudLicenseStatus.expired;
    }
  }
}

class BusinessRegistrationInput {
  const BusinessRegistrationInput({
    required this.businessName,
    required this.ownerName,
    required this.mobile,
    this.city,
    this.email,
  });

  final String businessName;
  final String ownerName;
  final String mobile;
  final String? city;
  final String? email;
}

class CloudLicenseRecord {
  const CloudLicenseRecord({
    required this.customerId,
    required this.deviceId,
    required this.status,
    required this.plan,
    required this.expiry,
    required this.remainingDays,
    required this.lastVerifiedAt,
  });

  final String customerId;
  final String deviceId;
  final CloudLicenseStatus status;
  final CloudLicensePlan plan;
  final DateTime? expiry;
  final int remainingDays;
  final DateTime lastVerifiedAt;

  bool get allowsAccess => status.allowsAccess;
}

class CloudLicenseCheckResult {
  const CloudLicenseCheckResult({
    required this.status,
    required this.plan,
    required this.expiry,
    required this.remainingDays,
    required this.isOfflineGrace,
    this.customerId,
    this.deviceId,
    this.message,
  });

  const CloudLicenseCheckResult.unregistered()
      : status = CloudLicenseStatus.unregistered,
        plan = CloudLicensePlan.trial,
        expiry = null,
        remainingDays = 0,
        isOfflineGrace = false,
        customerId = null,
        deviceId = null,
        message = null;

  const CloudLicenseCheckResult.internetRequired({this.message})
      : status = CloudLicenseStatus.internetRequired,
        plan = CloudLicensePlan.trial,
        expiry = null,
        remainingDays = 0,
        isOfflineGrace = false,
        customerId = null,
        deviceId = null;

  final CloudLicenseStatus status;
  final CloudLicensePlan plan;
  final DateTime? expiry;
  final int remainingDays;
  final bool isOfflineGrace;
  final String? customerId;
  final String? deviceId;
  final String? message;

  bool get allowsAccess => status.allowsAccess;
}
