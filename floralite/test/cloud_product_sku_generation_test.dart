import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/services/sku_generator_service.dart';

void main() {
  group('SkuGeneratorService', () {
    test('derives known category prefixes correctly', () {
      expect(SkuGeneratorService.deriveCategoryPrefix('Flowers'), 'FLW');
      expect(SkuGeneratorService.deriveCategoryPrefix('Fresh Flowers'), 'FLW');
      expect(SkuGeneratorService.deriveCategoryPrefix('Fillers'), 'FIL');
      expect(SkuGeneratorService.deriveCategoryPrefix('Foliage'), 'FOL');
      expect(SkuGeneratorService.deriveCategoryPrefix('Finished Products'), 'BQT');
      expect(SkuGeneratorService.deriveCategoryPrefix('Packing'), 'PCK');
      expect(SkuGeneratorService.deriveCategoryPrefix('Accessories'), 'ACC');
      expect(SkuGeneratorService.deriveCategoryPrefix('Plants'), 'PLT');
      expect(SkuGeneratorService.deriveCategoryPrefix('Others'), 'OTH');
    });

    test('derives custom category prefix using consonants', () {
      expect(SkuGeneratorService.deriveCategoryPrefix('Chocolates'), 'CHC');
      expect(SkuGeneratorService.deriveCategoryPrefix('Balloons'), 'BLL');
    });

    test('derives name code from product name', () {
      expect(SkuGeneratorService.deriveNameCode('Red Roses'), 'RDR');
      expect(SkuGeneratorService.deriveNameCode('Hydrangea'), 'HYD');
      expect(SkuGeneratorService.deriveNameCode('Orchid'), 'RCH');
    });

    test('generates full SKU with category, name, and random digits', () {
      final sku = SkuGeneratorService.generateSku(
        categoryName: 'Flowers',
        productName: 'Roses',
        randomDigits: 450,
      );
      expect(sku, 'FLW-RSS-450');
    });

    test('generates fallback SKU when product name is empty', () {
      final sku = SkuGeneratorService.generateSku(
        categoryName: 'Flowers',
        productName: '',
        randomDigits: 789,
      );
      expect(sku, 'FLW-789');
    });

    test('validates SKU format correctly', () {
      expect(SkuGeneratorService.isValidSku('FLW-ROS-123'), isTrue);
      expect(SkuGeneratorService.isValidSku('SKU_CUSTOM_99'), isTrue);
      expect(SkuGeneratorService.isValidSku(''), isFalse);
      expect(SkuGeneratorService.isValidSku('   '), isFalse);
      expect(SkuGeneratorService.isValidSku('A'), isFalse); // Min 2 chars
      expect(SkuGeneratorService.isValidSku('INVALID SKU!@#'), isFalse);
    });
  });
}
