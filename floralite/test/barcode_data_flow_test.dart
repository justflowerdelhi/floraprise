import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';

void main() {
  group('Barcode Data Flow & CloudProduct JSON tests', () {
    test('CloudProduct.fromJson deserializes barcode, manufacturerBarcode, and internalBarcode', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'companyId': '22222222-2222-2222-2222-222222222222',
        'name': 'Velvet Rose Bunch',
        'sku': 'ROSE-VEL-01',
        'barcode': 'VL0085425688009',
        'manufacturerBarcode': 'VL0085425688009',
        'internalBarcode': 'FL000042',
        'brand': 'FloraPrise Luxe',
        'retailPrice': 250.0,
        'costPrice': 120.0,
        'stockQuantity': 50,
        'trackInventory': true,
        'isActive': true,
      };

      final product = CloudProduct.fromJson(json);

      expect(product.id, '11111111-1111-1111-1111-111111111111');
      expect(product.name, 'Velvet Rose Bunch');
      expect(product.sku, 'ROSE-VEL-01');
      expect(product.barcode, 'VL0085425688009');
      expect(product.manufacturerBarcode, 'VL0085425688009');
      expect(product.internalBarcode, 'FL000042');
    });

    test('CloudProduct.fromJson handles missing or null barcodes gracefully', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Carnation Pink',
        'sku': 'CARN-PNK',
        'retailPrice': 30.0,
        'costPrice': 15.0,
      };

      final product = CloudProduct.fromJson(json);

      expect(product.barcode, isNull);
      expect(product.manufacturerBarcode, isNull);
      expect(product.internalBarcode, isNull);
    });

    test('CloudProduct.fromJson correctly parses PascalCase keys from ASP.NET Core', () {
      final json = {
        'Id': '33333333-3333-3333-3333-333333333333',
        'Name': 'Orchid Blue',
        'Sku': 'ORCH-BLU',
        'Barcode': 'VL0085425688009',
        'ManufacturerBarcode': 'VL0085425688009',
        'InternalBarcode': 'FL000099',
        'RetailPrice': 450.0,
        'CostPrice': 200.0,
      };

      final product = CloudProduct.fromJson(json);

      expect(product.id, '33333333-3333-3333-3333-333333333333');
      expect(product.name, 'Orchid Blue');
      expect(product.barcode, 'VL0085425688009');
      expect(product.manufacturerBarcode, 'VL0085425688009');
      expect(product.internalBarcode, 'FL000099');
    });

    test('CloudProduct.fromJson falls back between barcode and manufacturerBarcode seamlessly', () {
      final jsonWithOnlyBarcode = {
        'id': '44444444-4444-4444-4444-444444444444',
        'name': 'Custom Test Product',
        'sku': 'CUST-001',
        'barcode': '8906081923646',
      };

      final product1 = CloudProduct.fromJson(jsonWithOnlyBarcode);
      expect(product1.barcode, '8906081923646');
      expect(product1.manufacturerBarcode, '8906081923646');

      final jsonWithOnlyMfgBarcode = {
        'id': '55555555-5555-5555-5555-555555555555',
        'name': 'Custom Test Product 2',
        'sku': 'CUST-002',
        'manufacturerBarcode': '8906081923646',
      };

      final product2 = CloudProduct.fromJson(jsonWithOnlyMfgBarcode);
      expect(product2.barcode, '8906081923646');
      expect(product2.manufacturerBarcode, '8906081923646');
    });

    test('CloudProductInput toCreateJson and toUpdateJson serialize manufacturerBarcode into both fields', () {
      const input = CloudProductInput(
        name: 'Custom Test Product',
        sku: 'CUST-TEST-01',
        categoryId: 'cat-123',
        unitOfMeasure: 'Stem',
        retailPrice: 99.0,
        costPrice: 45.0,
        manufacturerBarcode: '8906081923646',
        description: 'Test product for barcode',
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 5,
      );

      final createJson = input.toCreateJson();
      expect(createJson['barcode'], '8906081923646');
      expect(createJson['manufacturerBarcode'], '8906081923646');

      final updateJson = input.toUpdateJson();
      expect(updateJson['barcode'], '8906081923646');
      expect(updateJson['manufacturerBarcode'], '8906081923646');
    });
  });
}
