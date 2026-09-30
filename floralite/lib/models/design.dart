class DesignRecord {
  final int id;
  final String? cloudId;
  final String bouquetId;
  final String? imagePath;
  final String description;
  final int? sellingPricePaise;
  final String? flowers;
  final String? occasion;
  final String? color;
  final String? collection;
  final String? notes;
  final String status;
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;

  const DesignRecord({
    required this.id,
    this.cloudId,
    required this.bouquetId,
    required this.imagePath,
    required this.description,
    required this.sellingPricePaise,
    required this.flowers,
    required this.occasion,
    required this.color,
    required this.collection,
    required this.notes,
    required this.status,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  String get sellingPriceLabel {
    if (sellingPricePaise == null || sellingPricePaise! <= 0) {
      return '';
    }
    return '₹${(sellingPricePaise! / 100).toStringAsFixed(0)}';
  }

  String get normalizedStatus {
    final value = status.trim().toLowerCase();
    if (value == 'ready') return 'ready';
    if (value == 'draft') return 'needs_review';
    if (value == 'needs review') return 'needs_review';
    if (value == 'needs_review') return 'needs_review';
    return 'needs_review';
  }

  bool get isReady => normalizedStatus == 'ready';

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'bouquet_id': bouquetId,
      'image_path': imagePath,
      'description': description,
      'selling_price_paise': sellingPricePaise,
      'flowers': flowers,
      'occasion': occasion,
      'color': color,
      'collection': collection,
      'notes': notes,
      'status': status,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DesignRecord.fromMap(Map<String, Object?> row) {
    final imageRef = (row['image_path'] ??
            row['imagePath'] ??
            row['imageReference'] ??
            row['image_url'] ??
            row['imageUrl'] ??
            row['design_ref'] ??
            row['designRef'])
        ?.toString();
    return DesignRecord(
      id: row['id'] as int,
      bouquetId: (row['bouquet_id'] ?? row['bouquetId'] ?? '') as String,
      imagePath: imageRef?.trim().isNotEmpty == true ? imageRef!.trim() : null,
      description: (row['description'] ?? '') as String,
      sellingPricePaise: row['selling_price_paise'] as int?,
      flowers: row['flowers'] as String?,
      occasion: row['occasion'] as String?,
      color: row['color'] as String?,
      collection: row['collection'] as String?,
      notes: row['notes'] as String?,
      status: (row['status'] as String?) ?? 'needs_review',
      isFavorite: (row['is_favorite'] as int? ?? 0) == 1,
      createdAt: (row['created_at'] ?? '') as String,
      updatedAt: (row['updated_at'] ?? '') as String,
    );
  }

  factory DesignRecord.fromCloudJson(Map<String, dynamic> json) {
    final guid = (json['id'] ?? json['Id'])?.toString() ?? '';
    final idInt = int.tryParse(guid) ?? guid.hashCode;
    final imageRef = (json['imageReference'] ??
            json['ImageReference'] ??
            json['imageUrl'] ??
            json['ImageUrl'] ??
            json['image_url'] ??
            json['imagePath'] ??
            json['ImagePath'] ??
            json['referenceImageUrl'] ??
            json['ReferenceImageUrl'] ??
            json['photoUrl'] ??
            json['PhotoUrl'] ??
            json['designRef'] ??
            json['design_ref'])
        ?.toString();
    final rawSellingPrice =
        json['sellingPricePaise'] ?? json['SellingPricePaise'];
    final sellingPricePaise =
        rawSellingPrice is num ? rawSellingPrice.toInt() : null;

    return DesignRecord(
      id: idInt,
      cloudId: guid,
      bouquetId: (json['bouquetId'] ?? json['BouquetId'] ?? json['bouquet_id'])?.toString() ?? '',
      imagePath: imageRef?.trim().isNotEmpty == true ? imageRef!.trim() : null,
      description: (json['description'] ?? json['Description'])?.toString() ?? '',
      sellingPricePaise: sellingPricePaise,
      flowers: (json['flowers'] ?? json['Flowers'])?.toString(),
      occasion: (json['occasion'] ?? json['Occasion'])?.toString(),
      color: (json['color'] ?? json['Color'])?.toString(),
      collection: (json['collection'] ?? json['Collection'])?.toString(),
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      status: (json['status'] ?? json['Status'])?.toString() ?? 'ready',
      isFavorite: (json['isFavorite'] ?? json['IsFavorite']) == true,
      createdAt: (json['createdAtUtc'] ?? json['CreatedAtUtc'] ?? json['createdAt'])?.toString() ?? '',
      updatedAt: (json['updatedAtUtc'] ?? json['UpdatedAtUtc'] ?? json['updatedAt'])?.toString() ?? '',
    );
  }
}
