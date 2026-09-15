import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';

void main() {
  group('CloudProductInput cost price', () {
    test('toCreateJson omits costPrice when not provided', () {
      const input = CloudProductInput(
        name: 'Rose',
        sku: 'SKU-1',
        categoryId: 'cat-1',
        unitOfMeasure: 'Stem',
        retailPrice: 100,
        manufacturerBarcode: null,
        description: null,
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 0,
      );

      final json = input.toCreateJson();

      expect(json.containsKey('costPrice'), isFalse);
      expect(json['retailPrice'], 100);
    });

    test('toCreateJson includes costPrice when provided', () {
      const input = CloudProductInput(
        name: 'Rose',
        sku: 'SKU-1',
        categoryId: 'cat-1',
        unitOfMeasure: 'Stem',
        retailPrice: 100,
        costPrice: 40,
        manufacturerBarcode: null,
        description: null,
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 0,
      );

      final json = input.toCreateJson();

      expect(json['costPrice'], 40);
    });

    test('toUpdateJson omits costPrice when not provided, preserving existing cost', () {
      const input = CloudProductInput(
        name: 'Rose',
        sku: 'SKU-1',
        categoryId: 'cat-1',
        unitOfMeasure: 'Stem',
        retailPrice: 120,
        manufacturerBarcode: null,
        description: null,
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 0,
      );

      final json = input.toUpdateJson();

      expect(json.containsKey('costPrice'), isFalse);
      expect(json['retailPrice'], 120);
    });

    test('toUpdateJson includes costPrice when a new value is provided', () {
      const input = CloudProductInput(
        name: 'Rose',
        sku: 'SKU-1',
        categoryId: 'cat-1',
        unitOfMeasure: 'Stem',
        retailPrice: 120,
        costPrice: 55,
        manufacturerBarcode: null,
        description: null,
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 0,
      );

      final json = input.toUpdateJson();

      expect(json['costPrice'], 55);
    });
  });
}
