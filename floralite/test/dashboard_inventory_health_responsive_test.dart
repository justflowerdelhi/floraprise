import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/widgets/dashboard/dashboard_inventory_health.dart';

void main() {
  group('Dashboard Inventory Health Responsive Layout Tests', () {
    final List<InventoryProductRecord> sampleProducts = [
      const InventoryProductRecord(
        productId: 1,
        name: 'Red Roses Dutch',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'ROSE-001',
        barcode: '1001',
        currentQty: 10,
        minQty: 5,
        trackInventory: true,
        gstPercent: 12,
        gstCalculationType: GstCalculationType.inclusive,
      ),
      const InventoryProductRecord(
        productId: 2,
        name: 'White Lilies Oriental',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'LIL-WHT-01',
        barcode: '1002',
        currentQty: 3,
        minQty: 5,
        trackInventory: true,
        gstPercent: 12,
        gstCalculationType: GstCalculationType.inclusive,
      ),
      const InventoryProductRecord(
        productId: 3,
        name: 'Pink Carnations',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'CAR-PNK-01',
        barcode: '1003',
        currentQty: 0,
        minQty: 5,
        trackInventory: true,
        gstPercent: 12,
        gstCalculationType: GstCalculationType.inclusive,
      ),
      const InventoryProductRecord(
        productId: 4,
        name: 'Wrapping Paper Gold',
        category: 'Packing',
        unit: 'Piece',
        sku: 'PAP-GLD-01',
        barcode: '1004',
        currentQty: 0,
        minQty: 0,
        trackInventory: false,
        gstPercent: 18,
        gstCalculationType: GstCalculationType.inclusive,
      ),
    ];

    final List<CloudLowStockProduct> sampleLowStock = [
      const CloudLowStockProduct(
        productId: 'p1',
        name: 'White Lilies Oriental',
        sku: 'LIL-WHT-01',
        currentQuantity: 3,
        minimumQuantity: 5,
        status: 'lowStock',
      ),
      const CloudLowStockProduct(
        productId: 'p2',
        name: 'Pink Carnations',
        sku: 'CAR-PNK-01',
        currentQuantity: 0,
        minimumQuantity: 5,
        status: 'outOfStock',
      ),
    ];

    final screenSizes = [
      const Size(360, 800), // Small Android (e.g. Galaxy A series)
      const Size(375, 812), // iPhone mini / Compact
      const Size(390, 844), // Standard Mobile
      const Size(412, 915), // Pixel / Large Android
    ];

    for (final size in screenSizes) {
      testWidgets('Renders without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DashboardInventoryHealth(
                  products: sampleProducts,
                  lowStockProducts: sampleLowStock,
                  isLoading: false,
                  onViewInventory: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all stock badges exist and render
        expect(find.text('In Stock (1)'), findsOneWidget);
        expect(find.text('Low Stock (1)'), findsOneWidget);
        expect(find.text('Out of Stock (1)'), findsOneWidget);
        expect(find.text('Untracked (1)'), findsOneWidget);

        // Verify low stock item list
        expect(find.text('White Lilies Oriental'), findsOneWidget);
        expect(find.text('Pink Carnations'), findsOneWidget);

        // Check for zero RenderFlex overflow errors
        expect(tester.takeException(), isNull);
      });
    }
  });
}
