class DesignRecord {
  final int id;
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
    return DesignRecord(
      id: row['id'] as int,
      bouquetId: row['bouquet_id'] as String,
      imagePath: row['image_path'] as String?,
      description: row['description'] as String,
      sellingPricePaise: row['selling_price_paise'] as int?,
      flowers: row['flowers'] as String?,
      occasion: row['occasion'] as String?,
      color: row['color'] as String?,
      collection: row['collection'] as String?,
      notes: row['notes'] as String?,
      status: (row['status'] as String?) ?? 'needs_review',
      isFavorite: (row['is_favorite'] as int? ?? 0) == 1,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    );
  }
}
