import '../database/app_database.dart';

class BusinessProfile {
  final int? id;
  final String shopName;
  final String ownerName;
  final String mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final bool gstRegistered;
  final String? gstNumber;
  final String createdAt;
  final String updatedAt;

  const BusinessProfile({
    this.id,
    required this.shopName,
    required this.ownerName,
    required this.mobileNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    required this.gstRegistered,
    this.gstNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessProfile copyWith({
    int? id,
    String? shopName,
    String? ownerName,
    String? mobileNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    bool? gstRegistered,
    String? gstNumber,
    String? createdAt,
    String? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      gstRegistered: gstRegistered ?? this.gstRegistered,
      gstNumber: gstNumber ?? this.gstNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      'owner_name': ownerName,
      'mobile_number': mobileNumber,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'gst_registered': gstRegistered ? 1 : 0,
      'gst_number': gstNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'] as int?,
      shopName: map['shop_name'] as String,
      ownerName: map['owner_name'] as String,
      mobileNumber: map['mobile_number'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      pinCode: map['pin_code'] as String?,
      gstRegistered: (map['gst_registered'] as int? ?? 0) == 1,
      gstNumber: map['gst_number'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

class BusinessProfileRepository {
  Future<BusinessProfile?> getBusinessProfile() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'business_profile',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return BusinessProfile.fromMap(rows.first);
  }

  Future<BusinessProfile> saveBusinessProfile({
    required String shopName,
    required String ownerName,
    required String mobileNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    required bool gstRegistered,
    String? gstNumber,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getBusinessProfile();

    final data = {
      'shop_name': shopName,
      'owner_name': ownerName,
      'mobile_number': mobileNumber,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'gst_registered': gstRegistered ? 1 : 0,
      'gst_number': gstRegistered ? gstNumber : null,
      'updated_at': now,
    };

    if (existing == null) {
      final id = await db.insert(
        'business_profile',
        {
          ...data,
          'created_at': now,
        },
      );
      return BusinessProfile.fromMap({
        ...data,
        'id': id,
        'created_at': now,
      });
    } else {
      await db.update(
        'business_profile',
        data,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.copyWith(
        shopName: shopName,
        ownerName: ownerName,
        mobileNumber: mobileNumber,
        email: email,
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        gstRegistered: gstRegistered,
        gstNumber: gstNumber,
        updatedAt: now,
      );
    }
  }

  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile) async {
    return saveBusinessProfile(
      shopName: profile.shopName,
      ownerName: profile.ownerName,
      mobileNumber: profile.mobileNumber,
      email: profile.email,
      address: profile.address,
      city: profile.city,
      state: profile.state,
      pinCode: profile.pinCode,
      gstRegistered: profile.gstRegistered,
      gstNumber: profile.gstNumber,
    );
  }
}
