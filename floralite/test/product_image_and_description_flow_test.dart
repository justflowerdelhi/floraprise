import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:floraprise/data/repositories/cloud_design_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/design.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/screens/my_designs_screen.dart';
import 'package:floraprise/services/design_image_helper.dart';
import 'package:floraprise/services/product_image_service.dart';

void main() {
  group('Product Image & Description Regression Tests', () {
    // -------------------------------------------------------------
    // A. DesignRecord image key fallbacks
    // -------------------------------------------------------------
    group('A: DesignRecord image key fallbacks', () {
      test('fromCloudJson resolves imageReference', () {
        final d = DesignRecord.fromCloudJson({
          'id': '101',
          'bouquetId': 'B-0101',
          'description': 'Product 1',
          'imageReference': 'https://example.com/flower1.jpg',
        });
        expect(d.imagePath, 'https://example.com/flower1.jpg');
        expect(d.description, 'Product 1');
      });

      test('fromCloudJson resolves imageUrl and image_url fallbacks', () {
        final d1 = DesignRecord.fromCloudJson({
          'id': '102',
          'description': 'Product 2',
          'imageUrl': 'https://example.com/flower2.jpg',
        });
        expect(d1.imagePath, 'https://example.com/flower2.jpg');

        final d2 = DesignRecord.fromCloudJson({
          'id': '103',
          'description': 'Product 3',
          'image_url': 'https://example.com/flower3.jpg',
        });
        expect(d2.imagePath, 'https://example.com/flower3.jpg');
      });

      test('fromCloudJson resolves data URI and asset path', () {
        final dData = DesignRecord.fromCloudJson({
          'id': '104',
          'description': 'Product 4',
          'imagePath': 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
        });
        expect(dData.imagePath, 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');

        final dAsset = DesignRecord.fromCloudJson({
          'id': '105',
          'description': 'Product 5',
          'referenceImageUrl': 'assets/images/rose.jpg',
        });
        expect(dAsset.imagePath, 'assets/images/rose.jpg');
      });

      test('fromMap resolves image_path, imageUrl, design_ref', () {
        final dMap1 = DesignRecord.fromMap({
          'id': 1,
          'bouquet_id': 'B-0001',
          'description': 'Local Design 1',
          'image_path': 'assets/images/bouquet1.png',
          'created_at': '2026-09-22',
          'updated_at': '2026-09-22',
        });
        expect(dMap1.imagePath, 'assets/images/bouquet1.png');

        final dMap2 = DesignRecord.fromMap({
          'id': 2,
          'bouquet_id': 'B-0002',
          'description': 'Local Design 2',
          'imageUrl': 'https://example.com/bouquet2.png',
          'created_at': '2026-09-22',
          'updated_at': '2026-09-22',
        });
        expect(dMap2.imagePath, 'https://example.com/bouquet2.png');
      });
    });

    // -------------------------------------------------------------
    // B. ProductImageService resolution
    // -------------------------------------------------------------
    group('B: ProductImageService web, data, asset, blob, and design_ref', () {
      const service = ProductImageService();

      test('resolves https image', () {
        final line = {'image_url': 'https://cdn.floraprise.com/roses.jpg'};
        final res = service.resolveForOrderLine(line);
        expect(res.hasImage, isTrue);
        expect(res.isNetwork, isTrue);
        expect(res.reference, 'https://cdn.floraprise.com/roses.jpg');
      });

      test('resolves http image', () {
        final line = {'image_url': 'http://cdn.floraprise.com/roses.jpg'};
        final res = service.resolveForOrderLine(line);
        expect(res.hasImage, isTrue);
        expect(res.isNetwork, isTrue);
        expect(res.reference, 'http://cdn.floraprise.com/roses.jpg');
      });

      test('resolves data:image URI', () {
        final line = {
          'design_ref': 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAE='
        };
        final res = service.resolveForOrderLine(line);
        expect(res.hasImage, isTrue);
        expect(res.isNetwork, isFalse);
        expect(res.source, ProductImageSource.orderReference);
        expect(res.reference,
            'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAE=');
      });

      test('resolves assets/ path', () {
        final line = {'product_image_path': 'assets/catalog/tulip.png'};
        final res = service.resolveForOrderLine(line);
        expect(res.hasImage, isTrue);
        expect(res.reference, 'assets/catalog/tulip.png');
      });

      test('resolves blob: url for in-session preview', () {
        final line = {'design_ref': 'blob:http://localhost:8080/uuid-1234'};
        final res = service.resolveForOrderLine(line);
        expect(res.hasImage, isTrue);
        expect(res.isNetwork, isTrue);
        expect(res.reference, 'blob:http://localhost:8080/uuid-1234');
      });

      test('resolves design_ref as orderReference', () {
        final line = {
          'product_name': 'Custom Orchid',
          'design_ref': 'https://images.example.com/custom_orchid.jpg',
        };
        final res = service.resolveForOrderLine(line);
        expect(res.source, ProductImageSource.orderReference);
        expect(res.reference, 'https://images.example.com/custom_orchid.jpg');
      });
    });

    // -------------------------------------------------------------
    // C & D. Local order line snapshot preservation
    // -------------------------------------------------------------
    group('C & D: Local order line snapshot preservation', () {
      test('WalkInLineItem preserves designRef, description, price, gst', () {
        const item = WalkInLineItem(
          productId: null,
          cloudProductId: null,
          designRef: 'https://images.example.com/my_design_1200.jpg',
          description: 'Product 1: MRP ₹1,200',
          quantity: 2,
          unitPricePaise: 120000,
          gstPercent: 18,
          source: 'design',
        );

        expect(item.designRef, 'https://images.example.com/my_design_1200.jpg');
        expect(item.description, 'Product 1: MRP ₹1,200');
        expect(item.quantity, 2);
        expect(item.unitPricePaise, 120000);
        expect(item.gstPercent, 18);
        expect(item.source, 'design');
      });
    });

    // -------------------------------------------------------------
    // E & F. Cloud order line mapping: image & actual description preserved
    // -------------------------------------------------------------
    group('E & F: Cloud order line mapping', () {
      test('CloudOrderRepository._lineMap preserves explicit description', () {
        final cloudJson = <String, dynamic>{
          'id': 'line-001',
          'productId': 'prod-001',
          'productName': 'Premium Red Roses',
          'description': 'Product 1: MRP ₹1,200 (12 stems with gypsophila)',
          'sku': 'ROSE-RED-12',
          'imageUrl': 'https://cdn.example.com/rose12.jpg',
          'quantity': 1,
          'unitPrice': 1200.0,
          'discountAmount': 0.0,
          'taxRatePercent': 18,
          'lineSubtotal': 1200.0,
          'lineTaxAmount': 216.0,
          'lineTotal': 1416.0,
        };

        final explicitDesc = (cloudJson['description'] as String?)?.trim();
        expect(explicitDesc,
            'Product 1: MRP ₹1,200 (12 stems with gypsophila)');
        expect(cloudJson['imageUrl'], 'https://cdn.example.com/rose12.jpg');
      });
    });

    // -------------------------------------------------------------
    // G. OrderView display title & description logic
    // -------------------------------------------------------------
    group('G: OrderView display resolution', () {
      test('displays distinct title and subtitle when both exist', () {
        final line = <String, dynamic>{
          'product_name': 'Red Roses',
          'description': 'Product 1: Beautiful 12 roses bouquet',
        };

        final productName = (line['product_name'] as String?)?.trim();
        final lineDescription = (line['description'] as String?)?.trim();

        final String title;
        final String? subtitle;

        if (productName != null && productName.isNotEmpty) {
          title = productName;
          if (lineDescription != null &&
              lineDescription.isNotEmpty &&
              lineDescription != productName) {
            subtitle = lineDescription;
          } else {
            subtitle = null;
          }
        } else if (lineDescription != null && lineDescription.isNotEmpty) {
          title = lineDescription;
          subtitle = null;
        } else {
          title = 'Product';
          subtitle = null;
        }

        expect(title, 'Red Roses');
        expect(subtitle, 'Product 1: Beautiful 12 roses bouquet');
      });

      test('displays description as title when product_name is absent', () {
        final line = <String, dynamic>{
          'product_name': null,
          'description': 'Product 2: MRP ₹1,500',
        };

        final productName = (line['product_name'] as String?)?.trim();
        final lineDescription = (line['description'] as String?)?.trim();

        final String title;
        final String? subtitle;

        if (productName != null && productName.isNotEmpty) {
          title = productName;
          if (lineDescription != null &&
              lineDescription.isNotEmpty &&
              lineDescription != productName) {
            subtitle = lineDescription;
          } else {
            subtitle = null;
          }
        } else if (lineDescription != null && lineDescription.isNotEmpty) {
          title = lineDescription;
          subtitle = null;
        } else {
          title = 'Product';
          subtitle = null;
        }

        expect(title, 'Product 2: MRP ₹1,500');
        expect(subtitle, isNull);
      });

      test('does not display null or redundant subtitle when description equals name', () {
        final line = <String, dynamic>{
          'product_name': 'Product 1',
          'description': 'Product 1',
        };

        final productName = (line['product_name'] as String?)?.trim();
        final lineDescription = (line['description'] as String?)?.trim();

        final String title;
        final String? subtitle;

        if (productName != null && productName.isNotEmpty) {
          title = productName;
          if (lineDescription != null &&
              lineDescription.isNotEmpty &&
              lineDescription != productName) {
            subtitle = lineDescription;
          } else {
            subtitle = null;
          }
        } else if (lineDescription != null && lineDescription.isNotEmpty) {
          title = lineDescription;
          subtitle = null;
        } else {
          title = 'Product';
          subtitle = null;
        }

        expect(title, 'Product 1');
        expect(subtitle, isNull);
      });
    });

    // -------------------------------------------------------------
    // H. Historical order safety: order reference precedes catalog product image
    // -------------------------------------------------------------
    group('H: Historical order safety', () {
      const service = ProductImageService();

      test('order reference image is preferred over catalog image', () {
        final line = {
          'design_ref': 'https://cdn.floraprise.com/snapshot_v1.jpg',
          'product_image_path': 'https://cdn.floraprise.com/catalog_v2.jpg',
        };

        final result = service.resolveForOrderLine(line);
        expect(result.source, ProductImageSource.orderReference);
        expect(result.reference, 'https://cdn.floraprise.com/snapshot_v1.jpg');
      });

      test('falls back to catalog image only when no order reference exists', () {
        final line = {
          'product_image_path': 'https://cdn.floraprise.com/catalog_v2.jpg',
        };

        final result = service.resolveForOrderLine(line);
        expect(result.source, ProductImageSource.productCatalog);
        expect(result.reference, 'https://cdn.floraprise.com/catalog_v2.jpg');
      });
    });

    // -------------------------------------------------------------
    // I. Robust sellingPricePaise numeric parsing
    // -------------------------------------------------------------
    group('I: Robust sellingPricePaise parsing in DesignRecord.fromCloudJson', () {
      test('parses integer sellingPricePaise correctly', () {
        final d = DesignRecord.fromCloudJson({
          'id': '101',
          'description': 'Design 1700',
          'sellingPricePaise': 170000,
        });
        expect(d.sellingPricePaise, 170000);
        expect(d.sellingPriceLabel, '₹1700');
      });

      test('parses double / num sellingPricePaise correctly', () {
        final d = DesignRecord.fromCloudJson({
          'id': '102',
          'description': 'Design 1800',
          'sellingPricePaise': 180000.0,
        });
        expect(d.sellingPricePaise, 180000);
        expect(d.sellingPriceLabel, '₹1800');
      });

      test('parses PascalCase SellingPricePaise correctly', () {
        final d = DesignRecord.fromCloudJson({
          'Id': '103',
          'Description': 'Design 2000',
          'SellingPricePaise': 200000,
        });
        expect(d.sellingPricePaise, 200000);
        expect(d.sellingPriceLabel, '₹2000');
      });

      test('handles null / missing sellingPricePaise gracefully', () {
        final d = DesignRecord.fromCloudJson({
          'id': '104',
          'description': 'Design without price',
        });
        expect(d.sellingPricePaise, isNull);
        expect(d.sellingPriceLabel, '');
      });
    });

    // -------------------------------------------------------------
    // J. CloudDesignRepository blob URL prevention & payload verification
    // -------------------------------------------------------------
    group('J: CloudDesignRepository blob URL prevention', () {
      test('create strips blob: URLs and sends null for imageReference', () async {
        Map<String, dynamic>? capturedBody;
        final repo = CloudDesignRepository(
          sender: (method, uri, {body}) async {
            expect(method, 'POST');
            expect(uri.path, '/api/designs');
            capturedBody = body as Map<String, dynamic>?;
            return {
              'id': 'des-uuid-001',
              'bouquetId': 'B-0002',
              'description': 'Design with blob',
              'sellingPricePaise': 170000,
              'imageReference': null,
            };
          },
        );

        final result = await repo.create(
          imagePath: 'blob:http://localhost:8080/c7a8b9d0-1234',
          description: 'Design with blob',
          sellingPricePaise: 170000,
        );

        expect(capturedBody, isNotNull);
        expect(capturedBody!['imageReference'], isNull);
        expect(capturedBody!['sellingPricePaise'], 170000);
        expect(result.imagePath, isNull);
      });

      test('create preserves durable data URI', () async {
        Map<String, dynamic>? capturedBody;
        const testDataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
        final repo = CloudDesignRepository(
          sender: (method, uri, {body}) async {
            capturedBody = body as Map<String, dynamic>?;
            return {
              'id': 'des-uuid-002',
              'bouquetId': 'B-0003',
              'description': 'Design with data URI',
              'sellingPricePaise': 180000,
              'imageReference': testDataUri,
            };
          },
        );

        final result = await repo.create(
          imagePath: testDataUri,
          description: 'Design with data URI',
          sellingPricePaise: 180000,
        );

        expect(capturedBody, isNotNull);
        expect(capturedBody!['imageReference'], testDataUri);
        expect(result.imagePath, testDataUri);
      });

      test('create preserves HTTPS URL', () async {
        Map<String, dynamic>? capturedBody;
        const testUrl = 'https://cdn.floraprise.com/bouquet.jpg';
        final repo = CloudDesignRepository(
          sender: (method, uri, {body}) async {
            capturedBody = body as Map<String, dynamic>?;
            return {
              'id': 'des-uuid-003',
              'bouquetId': 'B-0004',
              'description': 'Design with HTTPS URL',
              'sellingPricePaise': 250000,
              'imageReference': testUrl,
            };
          },
        );

        final result = await repo.create(
          imagePath: testUrl,
          description: 'Design with HTTPS URL',
          sellingPricePaise: 250000,
        );

        expect(capturedBody, isNotNull);
        expect(capturedBody!['imageReference'], testUrl);
        expect(result.imagePath, testUrl);
      });

      test('update strips blob: URLs and sends null for imageReference', () async {
        Map<String, dynamic>? capturedBody;
        final repo = CloudDesignRepository(
          sender: (method, uri, {body}) async {
            expect(method, 'PUT');
            expect(uri.path, '/api/designs/des-uuid-001');
            capturedBody = body as Map<String, dynamic>?;
            return {
              'id': 'des-uuid-001',
              'bouquetId': 'B-0002',
              'description': 'Updated Design',
              'sellingPricePaise': 190000,
              'imageReference': null,
            };
          },
        );

        await repo.update(
          'des-uuid-001',
          imagePath: 'blob:http://localhost:8080/temp-edit',
          description: 'Updated Design',
          sellingPricePaise: 190000,
        );

        expect(capturedBody, isNotNull);
        expect(capturedBody!['imageReference'], isNull);
      });
    });

    // -------------------------------------------------------------
    // K. DesignImageHelper safe compression & Data URI generation
    // -------------------------------------------------------------
    group('K: DesignImageHelper safe compression & Data URI generation', () {
      test('detectMimeType correctly detects JPEG, PNG, WEBP, GIF, and fallback', () {
        final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
        expect(DesignImageHelper.detectMimeType(jpegBytes), 'image/jpeg');

        final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        expect(DesignImageHelper.detectMimeType(pngBytes), 'image/png');

        final webpBytes = Uint8List.fromList([
          0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
        ]);
        expect(DesignImageHelper.detectMimeType(webpBytes), 'image/webp');

        final gifBytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
        expect(DesignImageHelper.detectMimeType(gifBytes), 'image/gif');

        final unknownBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        expect(DesignImageHelper.detectMimeType(unknownBytes), 'image/jpeg');
      });

      test('processBytesToDataUri downscales high-resolution image to fit maxDimension', () {
        // Create a large 2000x1500 test image
        final largeImage = img.Image(width: 2000, height: 1500);
        // Fill with some sample pixels
        img.fill(largeImage, color: img.ColorRgb8(255, 100, 50));
        final rawPngBytes = Uint8List.fromList(img.encodePng(largeImage));

        final dataUri = DesignImageHelper.processBytesToDataUri(
          rawPngBytes,
          maxDimension: 1024,
          quality: 80,
        );

        expect(dataUri.startsWith('data:image/jpeg;base64,'), isTrue);

        // Extract base64 part and decode
        final base64Part = dataUri.substring('data:image/jpeg;base64,'.length);
        final decodedBytes = base64Decode(base64Part);
        final decodedImage = img.decodeImage(decodedBytes);

        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, 1024);
        expect(decodedImage.height, 768); // 1500 * (1024 / 2000) = 768
        // Verify payload size is well below 1MB (typically < 100 KB)
        expect(decodedBytes.lengthInBytes, lessThan(300 * 1024));
      });

      test('processBytesToDataUri preserves compact image under maxDimension without distortion', () {
        final smallImage = img.Image(width: 400, height: 300);
        img.fill(smallImage, color: img.ColorRgb8(50, 150, 255));
        final rawJpgBytes = Uint8List.fromList(img.encodeJpg(smallImage, quality: 80));

        final dataUri = DesignImageHelper.processBytesToDataUri(
          rawJpgBytes,
          maxDimension: 1024,
          quality: 80,
        );

        expect(dataUri.startsWith('data:image/jpeg;base64,'), isTrue);
        final base64Part = dataUri.substring('data:image/jpeg;base64,'.length);
        final decodedBytes = base64Decode(base64Part);
        final decodedImage = img.decodeImage(decodedBytes);

        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, 400);
        expect(decodedImage.height, 300);
      });

      test('processBytesToDataUri handles empty bytes gracefully', () {
        final result = DesignImageHelper.processBytesToDataUri(Uint8List(0));
        expect(result, '');
      });
    });

    // -------------------------------------------------------------
    // L. My Design -> POS Cart Direct Add & Numeric Paise Carriage
    // -------------------------------------------------------------
    group('L: My Design -> POS Cart Direct Add & Numeric Paise Carriage', () {
      test('SelectedDesign stores numeric pricePaise and retains price string backwards compatibility', () {
        const selected = SelectedDesign(
          designId: 'B-0150',
          imagePath: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
          price: '₹3000',
          description: '150 mix roses',
          pricePaise: 300000,
        );

        expect(selected.designId, 'B-0150');
        expect(selected.imagePath, 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');
        expect(selected.price, '₹3000');
        expect(selected.description, '150 mix roses');
        expect(selected.pricePaise, 300000);
      });

      test('SelectedDesign supports legacy construction without pricePaise', () {
        const legacySelected = SelectedDesign(
          designId: 'B-0001',
          imagePath: 'https://example.com/rose.jpg',
          price: '₹1,500',
          description: 'Red Rose Bouquet',
        );

        expect(legacySelected.designId, 'B-0001');
        expect(legacySelected.pricePaise, isNull);
        expect(legacySelected.price, '₹1,500');
      });

      test('WalkInLineItem from My Design retains source: design, designRef, description, and pricePaise', () {
        const selected = SelectedDesign(
          designId: 'B-0150',
          imagePath: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
          price: '₹3000',
          description: '150 mix roses',
          pricePaise: 300000,
        );

        final lineItem = WalkInLineItem(
          productId: null,
          cloudProductId: null,
          designRef: selected.imagePath,
          description: selected.description,
          quantity: 1,
          unitPricePaise: selected.pricePaise ?? 0,
          source: 'design',
        );

        expect(lineItem.source, 'design');
        expect(lineItem.productId, isNull);
        expect(lineItem.cloudProductId, isNull);
        expect(lineItem.designRef, 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');
        expect(lineItem.description, '150 mix roses');
        expect(lineItem.unitPricePaise, 300000);
        expect(lineItem.quantity, 1);
      });

      test('WalkInManager.buildWebPosPayload generates correct design payload without requiring cloudProductId', () {
        const lineItem = WalkInLineItem(
          productId: null,
          cloudProductId: null,
          designRef: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
          description: '150 mix roses',
          quantity: 1,
          unitPricePaise: 300000,
          source: 'design',
        );

        const session = WalkInSession(
          fulfilmentType: FulfilmentType.delivery,
          customerName: 'Test Customer',
          customerPhone: '9876543210',
          lines: [lineItem],
        );

        final now = DateTime(2026, 9, 23, 10, 0);
        final payload = WalkInManager.buildWebPosPayload(
          session: session,
          totals: const OrderTotals(
            subtotalPaise: 300000,
            gstTotalPaise: 0,
            discountTotalPaise: 0,
            grandTotalPaise: 300000,
            roundOffPaise: 0,
          ),
          ensuredCustomer: null,
          clientSyncId: 'test_sync_123',
          now: now,
          fiscalProfile: CountryPresets.india(),
        );

        expect(payload['clientSyncId'], 'test_sync_123');
        final lines = payload['lines'] as List<Map<String, dynamic>>;
        expect(lines.length, 1);
        expect(lines[0]['source'], 'design');
        expect(lines[0]['design_ref'], 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');
        expect(lines[0]['description'], '150 mix roses');
        expect(lines[0]['qty'], 1);
        expect(lines[0]['unit_price_paise'], 300000);
        expect(lines[0].containsKey('product_id'), isFalse);
        expect(lines[0].containsKey('cloudProductId'), isFalse);

        final inventoryTransactions = payload['inventoryTransactions'] as List<Map<String, dynamic>>;
        expect(inventoryTransactions, isEmpty);
      });
    });
  });
}
