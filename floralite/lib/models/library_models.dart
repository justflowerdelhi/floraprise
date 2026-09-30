
class LibraryCategory {
  const LibraryCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.iconKey,
    this.parentCategoryId,
    this.parentCategoryName,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? iconKey;
  final String? parentCategoryId;
  final String? parentCategoryName;
  final int sortOrder;
  final bool isActive;
  final int productCount;

  factory LibraryCategory.fromJson(Map<String, dynamic> json) {
    return LibraryCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      iconKey: json['iconKey']?.toString(),
      parentCategoryId: json['parentCategoryId']?.toString(),
      parentCategoryName: json['parentCategoryName']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class LibraryCategoryTree {
  const LibraryCategoryTree({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.iconKey,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? iconKey;
  final int sortOrder;
  final bool isActive;
  final int productCount;
  final List<LibraryCategoryTree> children;

  factory LibraryCategoryTree.fromJson(Map<String, dynamic> json) {
    return LibraryCategoryTree(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      iconKey: json['iconKey']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => LibraryCategoryTree.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class LibraryProduct {
  const LibraryProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryId,
    this.categoryName,
    this.productType = 'SingleFlower',
    this.standardUnit = 'Stem',
    this.standardSku,
    this.referenceImageUrl,
    this.thumbnailUrl,
    this.description,
    this.searchKeywords,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String name;
  final String slug;
  final String? categoryId;
  final String? categoryName;
  final String productType;
  final String standardUnit;
  final String? standardSku;
  final String? referenceImageUrl;
  final String? thumbnailUrl;
  final String? description;
  final String? searchKeywords;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryProduct.fromJson(Map<String, dynamic> json) {
    return LibraryProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      productType: json['productType']?.toString() ?? 'SingleFlower',
      standardUnit: json['standardUnit']?.toString() ?? 'Stem',
      standardSku: json['standardSku']?.toString(),
      referenceImageUrl: json['referenceImageUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      description: json['description']?.toString(),
      searchKeywords: json['searchKeywords']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LibraryRecipeItem {
  const LibraryRecipeItem({
    required this.id,
    this.libraryProductId,
    this.libraryProductName,
    required this.productName,
    required this.quantity,
    required this.unit,
    this.notes,
    this.sortOrder = 0,
  });

  final String id;
  final String? libraryProductId;
  final String? libraryProductName;
  final String productName;
  final double quantity;
  final String unit;
  final String? notes;
  final int sortOrder;

  factory LibraryRecipeItem.fromJson(Map<String, dynamic> json) {
    return LibraryRecipeItem(
      id: json['id']?.toString() ?? '',
      libraryProductId: json['libraryProductId']?.toString(),
      libraryProductName: json['libraryProductName']?.toString(),
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'Stem',
      notes: json['notes']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class LibraryRecipe {
  const LibraryRecipe({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.yieldQuantity = 1.0,
    this.yieldUnit = 'Piece',
    this.instructions,
    this.preparationNotes,
    this.itemCount = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
    this.items = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double yieldQuantity;
  final String? yieldUnit;
  final String? instructions;
  final String? preparationNotes;
  final int itemCount;
  final int sortOrder;
  final bool isActive;
  final int version;
  final List<LibraryRecipeItem> items;

  factory LibraryRecipe.fromJson(Map<String, dynamic> json) {
    return LibraryRecipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      yieldQuantity: (json['yieldQuantity'] as num?)?.toDouble() ?? 1.0,
      yieldUnit: json['yieldUnit']?.toString() ?? 'Piece',
      instructions: json['instructions']?.toString(),
      preparationNotes: json['preparationNotes']?.toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => LibraryRecipeItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class LibraryDesign {
  const LibraryDesign({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.highResImageUrl,
    this.thumbnailUrl,
    this.occasion,
    this.style,
    this.colorPalette,
    this.flowerTypes,
    this.recipeId,
    this.recipeName,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String title;
  final String slug;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String? highResImageUrl;
  final String? thumbnailUrl;
  final String? occasion;
  final String? style;
  final String? colorPalette;
  final String? flowerTypes;
  final String? recipeId;
  final String? recipeName;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryDesign.fromJson(Map<String, dynamic> json) {
    return LibraryDesign(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      highResImageUrl: json['highResImageUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      occasion: json['occasion']?.toString(),
      style: json['style']?.toString(),
      colorPalette: json['colorPalette']?.toString(),
      flowerTypes: json['flowerTypes']?.toString(),
      recipeId: json['recipeId']?.toString(),
      recipeName: json['recipeName']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LibraryCardTemplate {
  const LibraryCardTemplate({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.occasion,
    this.tone,
    this.language = 'en',
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String title;
  final String slug;
  final String content;
  final String? occasion;
  final String? tone;
  final String language;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryCardTemplate.fromJson(Map<String, dynamic> json) {
    return LibraryCardTemplate(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      occasion: json['occasion']?.toString(),
      tone: json['tone']?.toString(),
      language: json['language']?.toString() ?? 'en',
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LibraryCardOccasionSummary {
  const LibraryCardOccasionSummary({
    required this.occasion,
    required this.count,
  });

  final String occasion;
  final int count;

  factory LibraryCardOccasionSummary.fromJson(Map<String, dynamic> json) {
    return LibraryCardOccasionSummary(
      occasion: json['occasion']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LibraryTutorial {
  const LibraryTutorial({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    required this.contentMarkdown,
    this.categoryId,
    this.categoryName,
    this.videoUrl,
    this.thumbnailUrl,
    this.difficultyLevel = 'Beginner',
    this.estimatedReadingMinutes = 5,
    this.tags,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String title;
  final String slug;
  final String? summary;
  final String contentMarkdown;
  final String? categoryId;
  final String? categoryName;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String difficultyLevel;
  final int? estimatedReadingMinutes;
  final String? tags;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryTutorial.fromJson(Map<String, dynamic> json) {
    return LibraryTutorial(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      summary: json['summary']?.toString(),
      contentMarkdown: json['contentMarkdown']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      difficultyLevel: json['difficultyLevel']?.toString() ?? 'Beginner',
      estimatedReadingMinutes: (json['estimatedReadingMinutes'] as num?)?.toInt() ?? 5,
      tags: json['tags']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LibraryManifest {
  const LibraryManifest({
    required this.categoriesVersion,
    required this.categoriesCount,
    required this.productsVersion,
    required this.productsCount,
    required this.recipesVersion,
    required this.recipesCount,
    required this.designsVersion,
    required this.designsCount,
    required this.cardsVersion,
    required this.cardsCount,
    required this.tutorialsVersion,
    required this.tutorialsCount,
    required this.globalManifestHash,
    required this.generatedAtUtc,
  });

  final String categoriesVersion;
  final int categoriesCount;
  final String productsVersion;
  final int productsCount;
  final String recipesVersion;
  final int recipesCount;
  final String designsVersion;
  final int designsCount;
  final String cardsVersion;
  final int cardsCount;
  final String tutorialsVersion;
  final int tutorialsCount;
  final String globalManifestHash;
  final DateTime generatedAtUtc;

  factory LibraryManifest.fromJson(Map<String, dynamic> json) {
    return LibraryManifest(
      categoriesVersion: json['categoriesVersion']?.toString() ?? '',
      categoriesCount: (json['categoriesCount'] as num?)?.toInt() ?? 0,
      productsVersion: json['productsVersion']?.toString() ?? '',
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      recipesVersion: json['recipesVersion']?.toString() ?? '',
      recipesCount: (json['recipesCount'] as num?)?.toInt() ?? 0,
      designsVersion: json['designsVersion']?.toString() ?? '',
      designsCount: (json['designsCount'] as num?)?.toInt() ?? 0,
      cardsVersion: json['cardsVersion']?.toString() ?? '',
      cardsCount: (json['cardsCount'] as num?)?.toInt() ?? 0,
      tutorialsVersion: json['tutorialsVersion']?.toString() ?? '',
      tutorialsCount: (json['tutorialsCount'] as num?)?.toInt() ?? 0,
      globalManifestHash: json['globalManifestHash']?.toString() ?? '',
      generatedAtUtc: DateTime.tryParse(json['generatedAtUtc']?.toString() ?? '') ?? DateTime.now().toUtc(),
    );
  }
}

class LibraryImportResult {
  const LibraryImportResult({
    required this.success,
    required this.alreadyImported,
    this.importedId,
    required this.message,
  });

  final bool success;
  final bool alreadyImported;
  final String? importedId;
  final String message;

  factory LibraryImportResult.fromJson(Map<String, dynamic> json) {
    return LibraryImportResult(
      success: json['success'] as bool? ?? false,
      alreadyImported: json['alreadyImported'] as bool? ?? false,
      importedId: (json['productId'] ?? json['recipeId'] ?? json['designId'])?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}

class LibraryFestival {
  const LibraryFestival({
    required this.id,
    required this.name,
    required this.slug,
    required this.festivalDate,
    this.month = 1,
    this.day = 1,
    this.description,
    this.isRecurring = true,
    this.flowerDemands,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String name;
  final String slug;
  final DateTime festivalDate;
  final int month;
  final int day;
  final String? description;
  final bool isRecurring;
  final String? flowerDemands;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryFestival.fromJson(Map<String, dynamic> json) {
    return LibraryFestival(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      festivalDate: DateTime.tryParse(json['festivalDate']?.toString() ?? '') ?? DateTime.now(),
      month: (json['month'] as num?)?.toInt() ?? 1,
      day: (json['day'] as num?)?.toInt() ?? 1,
      description: json['description']?.toString(),
      isRecurring: json['isRecurring'] as bool? ?? true,
      flowerDemands: json['flowerDemands']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LibraryWeddingDate {
  const LibraryWeddingDate({
    required this.id,
    required this.title,
    required this.slug,
    required this.weddingDate,
    this.tithi,
    this.nakshatra,
    this.notes,
    this.season,
    this.demandLevel = 'High',
    this.sortOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  final String id;
  final String title;
  final String slug;
  final DateTime weddingDate;
  final String? tithi;
  final String? nakshatra;
  final String? notes;
  final String? season;
  final String demandLevel;
  final int sortOrder;
  final bool isActive;
  final int version;

  factory LibraryWeddingDate.fromJson(Map<String, dynamic> json) {
    return LibraryWeddingDate(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      weddingDate: DateTime.tryParse(json['weddingDate']?.toString() ?? '') ?? DateTime.now(),
      tithi: json['tithi']?.toString(),
      nakshatra: json['nakshatra']?.toString(),
      notes: json['notes']?.toString(),
      season: json['season']?.toString(),
      demandLevel: json['demandLevel']?.toString() ?? 'High',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

