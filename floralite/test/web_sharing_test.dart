import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/design.dart';
import 'package:floraprise/models/share_branding.dart';
import 'package:floraprise/services/design_share_image_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const testSettings = ShareBrandingSettings(
    showPrice: true,
    showShopName: true,
    showPhoneNumber: true,
    showLogo: false,
    showWatermark: false,
    showWatermarkBusinessName: false,
    showWatermarkCity: false,
    watermarkOpacity: 0.5,
    watermarkSize: WatermarkSize.medium,
    watermarkPosition: WatermarkPosition.bottomRight,
    showWebsite: false,
    footerColor: Colors.purple,
  );

  test('generateBrandedJpegBytes generates valid composite image bytes from data URI', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 10, 10));
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..color = const ui.Color(0xFFFF0000));
    final img = await recorder.endRecording().toImage(10, 10);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final base64Png = base64Encode(byteData!.buffer.asUint8List());
    final dataUri = 'data:image/png;base64,$base64Png';

    final service = DesignShareImageService();
    final design = DesignRecord(
      id: 1,
      bouquetId: 'BQ-001',
      description: 'Rose Bouquet',
      flowers: 'Red Roses, Gypsophila',
      sellingPricePaise: 50000,
      imagePath: dataUri,
      occasion: 'Birthday',
      color: 'Red',
      collection: 'Classic',
      notes: '',
      status: 'ready',
      isFavorite: false,
      createdAt: '2026-09-20',
      updatedAt: '2026-09-20',
    );

    final bytes = await service.generateBrandedJpegBytes(
      design: design,
      settings: testSettings,
      variant: DesignShareVariant.brandedPreview,
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('generateBrandedJpegXFile returns XFile with mimeType image/jpeg', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 10, 10));
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..color = const ui.Color(0xFF00FF00));
    final img = await recorder.endRecording().toImage(10, 10);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final base64Png = base64Encode(byteData!.buffer.asUint8List());
    final dataUri = 'data:image/png;base64,$base64Png';

    final service = DesignShareImageService();
    final design = DesignRecord(
      id: 2,
      bouquetId: 'BQ-002',
      description: 'Lily Bouquet',
      flowers: 'Lilies',
      sellingPricePaise: 75000,
      imagePath: dataUri,
      occasion: 'Anniversary',
      color: 'White',
      collection: 'Premium',
      notes: '',
      status: 'ready',
      isFavorite: false,
      createdAt: '2026-09-20',
      updatedAt: '2026-09-20',
    );

    final xfile = await service.generateBrandedJpegXFile(
      design: design,
      settings: testSettings,
      variant: DesignShareVariant.quotation,
    );

    expect(xfile.mimeType, 'image/jpeg');
    expect(xfile.name, contains('floraprise_share_2_'));
    final readBytes = await xfile.readAsBytes();
    expect(readBytes, isNotEmpty);
  });
}
