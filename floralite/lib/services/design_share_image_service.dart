import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/design.dart';
import '../models/share_branding.dart';
import 'share_branding_settings_service.dart';

class DesignShareImageService {
  DesignShareImageService({
    ShareBrandingSettingsService? brandingSettingsService,
  }) : _brandingSettingsService =
            brandingSettingsService ?? ShareBrandingSettingsService();

  final ShareBrandingSettingsService _brandingSettingsService;

  Future<File> generateBrandedJpeg({
    required DesignRecord design,
    required ShareBrandingSettings settings,
    required DesignShareVariant variant,
  }) async {
    final sourcePath = design.imagePath?.trim() ?? '';
    if (sourcePath.isEmpty) {
      throw StateError('Design image is not available for sharing.');
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Design image file not found.');
    }

    final identity = await _brandingSettingsService.loadBrandingIdentity();
    final sourceImage = await _decodeImageFromPath(sourcePath);
    ui.Image? logoImage;
    if (settings.showWatermark &&
        settings.showLogo &&
        identity.logoPath.isNotEmpty) {
      final logoFile = File(identity.logoPath);
      if (await logoFile.exists()) {
        try {
          logoImage = await _decodeImageFromPath(identity.logoPath);
        } catch (_) {
          logoImage = null;
        }
      }
    }

    const minWidth = 1080.0;
    final outputWidth = math.max(minWidth, sourceImage.width.toDouble());
    final imageScale = outputWidth / sourceImage.width;
    final outputImageHeight = sourceImage.height * imageScale;
    final footerHeight = variant == DesignShareVariant.quotation
        ? math.max(340.0, outputWidth * 0.36)
        : math.max(220.0, outputWidth * 0.22);
    final outputHeight = outputImageHeight + footerHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outputWidth, outputHeight),
    );

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, outputWidth, outputHeight), backgroundPaint);

    _drawPhoto(canvas, sourceImage, outputWidth, outputImageHeight);

    if (settings.showWatermark) {
      _drawGlassWatermark(
        canvas,
        sourceImage: sourceImage,
        logo: logoImage,
        identity: identity,
        settings: settings,
        width: outputWidth,
        imageHeight: outputImageHeight,
      );
    }

    final footerColor = settings.footerColor;
    canvas.drawRect(
      Rect.fromLTWH(0, outputImageHeight, outputWidth, footerHeight),
      Paint()..color = footerColor,
    );

    final footerTextColor =
        ThemeData.estimateBrightnessForColor(footerColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    if (variant == DesignShareVariant.quotation) {
      _drawQuotationFooter(
        canvas,
        design: design,
        identity: identity,
        settings: settings,
        textColor: footerTextColor,
        width: outputWidth,
        top: outputImageHeight,
        height: footerHeight,
      );
    } else {
      _drawBrandedFooter(
        canvas,
        design: design,
        identity: identity,
        settings: settings,
        textColor: footerTextColor,
        width: outputWidth,
        top: outputImageHeight,
        height: footerHeight,
      );
    }

    final composed = await recorder.endRecording().toImage(
          outputWidth.round(),
          outputHeight.round(),
        );
    final pngBytes = await composed.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) {
      throw StateError('Unable to prepare image for sharing.');
    }

    final jpgBytes = _convertPngToJpeg(pngBytes.buffer.asUint8List());
    final directory = await getTemporaryDirectory();
    final fileName =
        'floraprise_share_${design.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File(p.join(directory.path, fileName));
    await outputFile.writeAsBytes(jpgBytes, flush: true);
    return outputFile;
  }

  void _drawPhoto(
    Canvas canvas,
    ui.Image sourceImage,
    double width,
    double height,
  ) {
    final src = Rect.fromLTWH(
      0,
      0,
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, width, height);
    canvas.drawImageRect(sourceImage, src, dst, Paint());
  }

  void _drawGlassWatermark(
    Canvas canvas, {
    required ui.Image sourceImage,
    required ui.Image? logo,
    required ShareBrandingIdentity identity,
    required ShareBrandingSettings settings,
    required double width,
    required double imageHeight,
  }) {
    final showLogo = settings.showLogo && logo != null;
    final businessName =
        settings.showWatermarkBusinessName ? identity.shopName.trim() : '';
    final city = settings.showWatermarkCity ? identity.city.trim() : '';
    if (!showLogo && businessName.isEmpty && city.isEmpty) return;

    final sizeFactor = switch (settings.watermarkSize) {
      WatermarkSize.small => 0.56,
      WatermarkSize.medium => 0.68,
      WatermarkSize.large => 0.80,
    };
    final cardWidth = width * sizeFactor;
    final cardHeight = width *
        switch (settings.watermarkSize) {
          WatermarkSize.small => 0.105,
          WatermarkSize.medium => 0.125,
          WatermarkSize.large => 0.145,
        };
    final margin = width * 0.035;
    final left = switch (settings.watermarkPosition) {
      WatermarkPosition.topLeft || WatermarkPosition.bottomLeft => margin,
      WatermarkPosition.topCenter ||
      WatermarkPosition.bottomCenter =>
        (width - cardWidth) / 2,
      WatermarkPosition.topRight ||
      WatermarkPosition.bottomRight =>
        width - cardWidth - margin,
    };
    final top = switch (settings.watermarkPosition) {
      WatermarkPosition.topLeft ||
      WatermarkPosition.topCenter ||
      WatermarkPosition.topRight =>
        margin,
      WatermarkPosition.bottomLeft ||
      WatermarkPosition.bottomCenter ||
      WatermarkPosition.bottomRight =>
        imageHeight - cardHeight - margin,
    };
    final cardRect = Rect.fromLTWH(left, top, cardWidth, cardHeight);
    final radius = Radius.circular(cardHeight * 0.24);
    final card = RRect.fromRectAndRadius(cardRect, radius);
    final opacity = settings.watermarkOpacity.clamp(0.2, 1.0);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.20 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.012);
    canvas.drawRRect(card.shift(Offset(0, width * 0.008)), shadow);

    canvas.save();
    canvas.clipRRect(card);
    canvas.drawImageRect(
      sourceImage,
      Rect.fromLTWH(
        0,
        0,
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, width, imageHeight),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
    );
    canvas.drawRRect(
      card,
      Paint()..color = Colors.white.withValues(alpha: 0.30 * opacity),
    );
    canvas.restore();

    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, width * 0.0018)
        ..color = Colors.white.withValues(alpha: 0.68 * opacity),
    );

    final padding = cardHeight * 0.18;
    var textLeft = cardRect.left + padding;
    if (showLogo) {
      final logoSize = cardHeight * 0.64;
      final logoRect = Rect.fromLTWH(
        cardRect.left + padding,
        cardRect.top + (cardHeight - logoSize) / 2,
        logoSize,
        logoSize,
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(logoRect));
      paintImage(
        canvas: canvas,
        rect: logoRect,
        image: logo,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
      canvas.drawOval(
        logoRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, width * 0.002)
          ..color = Colors.white.withValues(alpha: 0.82 * opacity),
      );
      textLeft = logoRect.right + padding * 0.72;
    }

    final textWidth = cardRect.right - padding - textLeft;
    final namePainter = TextPainter(
      text: TextSpan(
        text: businessName,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: cardHeight * 0.28,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Color(0x59000000), blurRadius: 5)],
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);
    final cityPainter = TextPainter(
      text: TextSpan(
        text: city,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.86 * opacity),
          fontSize: cardHeight * 0.19,
          fontWeight: FontWeight.w500,
          shadows: const [Shadow(color: Color(0x59000000), blurRadius: 4)],
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);
    final gap =
        businessName.isNotEmpty && city.isNotEmpty ? cardHeight * 0.035 : 0.0;
    final textHeight = namePainter.height + cityPainter.height + gap;
    var textTop = cardRect.top + (cardHeight - textHeight) / 2;
    if (businessName.isNotEmpty) {
      namePainter.paint(canvas, Offset(textLeft, textTop));
      textTop += namePainter.height + gap;
    }
    if (city.isNotEmpty) {
      cityPainter.paint(canvas, Offset(textLeft, textTop));
    }
  }

  void _drawBrandedFooter(
    Canvas canvas, {
    required DesignRecord design,
    required ShareBrandingIdentity identity,
    required ShareBrandingSettings settings,
    required Color textColor,
    required double width,
    required double top,
    required double height,
  }) {
    final left = width * 0.05;
    final rightWidth = width * 0.3;
    final availableWidth = width - left - rightWidth - 16;

    final title = design.description.trim().isNotEmpty
        ? design.description.trim()
        : design.bouquetId.trim();

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: textColor,
          fontSize: math.max(34, width * 0.033),
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 2,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);

    var y = top + 18;
    titlePainter.paint(canvas, Offset(left, y));
    y += titlePainter.height + 10;

    if (settings.showShopName && identity.shopName.isNotEmpty) {
      y = _paintLine(
        canvas,
        text: identity.shopName,
        x: left,
        y: y,
        maxWidth: availableWidth,
        color: textColor,
      );
    }

    if (settings.showPhoneNumber && identity.phoneNumber.isNotEmpty) {
      y = _paintLine(
        canvas,
        text: 'Phone: ${identity.phoneNumber}',
        x: left,
        y: y,
        maxWidth: availableWidth,
        color: textColor,
      );
    }

    if (settings.showWebsite && identity.website.isNotEmpty) {
      y = _paintLine(
        canvas,
        text: identity.website,
        x: left,
        y: y,
        maxWidth: availableWidth,
        color: textColor,
      );
    }

    if (settings.showPrice && (design.sellingPricePaise ?? 0) > 0) {
      final price =
          '₹${((design.sellingPricePaise ?? 0) / 100).toStringAsFixed(0)}';
      final pricePainter = TextPainter(
        text: TextSpan(
          text: price,
          style: TextStyle(
            color: textColor,
            fontSize: math.max(46, width * 0.048),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rightWidth);
      pricePainter.paint(
        canvas,
        Offset(
            width - rightWidth - 20, top + (height - pricePainter.height) / 2),
      );
    }
  }

  void _drawQuotationFooter(
    Canvas canvas, {
    required DesignRecord design,
    required ShareBrandingIdentity identity,
    required ShareBrandingSettings settings,
    required Color textColor,
    required double width,
    required double top,
    required double height,
  }) {
    final left = width * 0.05;
    final maxWidth = width * 0.9;
    var y = top + 18;

    if (settings.showShopName && identity.shopName.isNotEmpty) {
      final shopPainter = TextPainter(
        text: TextSpan(
          text: identity.shopName,
          style: TextStyle(
            color: textColor,
            fontSize: math.max(40, width * 0.037),
            fontWeight: FontWeight.w800,
          ),
        ),
        maxLines: 1,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      shopPainter.paint(canvas, Offset(left, y));
      y += shopPainter.height + 8;
    }

    y = _paintLine(
      canvas,
      text: design.description.trim().isEmpty
          ? design.bouquetId.trim()
          : design.description.trim(),
      x: left,
      y: y,
      maxWidth: maxWidth,
      color: textColor,
      fontSize: math.max(34, width * 0.032),
      fontWeight: FontWeight.w700,
      maxLines: 2,
    );

    if (settings.showPrice && (design.sellingPricePaise ?? 0) > 0) {
      y = _paintLine(
        canvas,
        text: '₹${((design.sellingPricePaise ?? 0) / 100).toStringAsFixed(0)}',
        x: left,
        y: y + 6,
        maxWidth: maxWidth,
        color: textColor,
        fontSize: math.max(48, width * 0.045),
        fontWeight: FontWeight.w900,
      );
    }

    y = _paintLine(
      canvas,
      text: 'Fresh Flowers Included',
      x: left,
      y: y + 6,
      maxWidth: maxWidth,
      color: textColor,
      fontWeight: FontWeight.w700,
    );

    final flowers = _flowerLines(design.flowers);
    for (final item in flowers.take(3)) {
      y = _paintLine(
        canvas,
        text: '• $item',
        x: left,
        y: y,
        maxWidth: maxWidth,
        color: textColor,
      );
    }

    if (settings.showPhoneNumber && identity.phoneNumber.isNotEmpty) {
      y = _paintLine(
        canvas,
        text: 'Call / WhatsApp ${identity.phoneNumber}',
        x: left,
        y: y + 6,
        maxWidth: maxWidth,
        color: textColor,
        fontWeight: FontWeight.w700,
      );
    }

    if (settings.showWebsite && identity.website.isNotEmpty) {
      _paintLine(
        canvas,
        text: identity.website,
        x: left,
        y: y,
        maxWidth: maxWidth,
        color: textColor,
      );
    }
  }

  double _paintLine(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required double maxWidth,
    required Color color,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    int maxLines = 1,
  }) {
    if (text.trim().isEmpty) return y;
    final painter = TextPainter(
      text: TextSpan(
        text: text.trim(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      maxLines: maxLines,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
    return y + painter.height + 4;
  }

  List<String> _flowerLines(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const ['Premium flowers'];
    }
    return source
        .split(RegExp(r'[,\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<ui.Image> _decodeImageFromPath(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Uint8List _convertPngToJpeg(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw StateError('Unable to generate share image.');
    }
    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: 92),
    );
  }
}
