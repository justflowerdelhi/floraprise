import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Helper class to process, resize, and compress images for Web persistence
/// ensuring payloads comfortably fit within backend and reverse-proxy payload limits (e.g. Nginx 1MB).
class DesignImageHelper {
  const DesignImageHelper._();

  /// Default max dimension (width or height) for stored design photos.
  static const int defaultMaxDimension = 1024;

  /// Default JPEG compression quality (0-100).
  static const int defaultQuality = 80;

  /// Maximum byte size of raw image bytes before forcing compression/downscaling (512 KB).
  /// A 512 KB binary image produces ~682 KB in Base64, well below Nginx's 1MB ceiling.
  static const int defaultMaxSafeBytes = 512 * 1024;

  /// Detects the MIME type of the given image bytes by inspecting magic header bytes.
  static String detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  /// Processes raw image bytes for Web storage:
  /// 1. Inspects image dimensions and raw byte size.
  /// 2. If exceeding [maxDimension] or [maxSafeBytes], decodes, resizes, and compresses to JPEG.
  /// 3. Returns a clean, durable `data:<mime>;base64,<encoded>` Data URI.
  static String processBytesToDataUri(
    Uint8List bytes, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
    int maxSafeBytes = defaultMaxSafeBytes,
  }) {
    if (bytes.isEmpty) {
      return '';
    }

    final detectedMime = detectMimeType(bytes);

    // If already compact and within safe byte limits, attempt a lightweight check
    if (bytes.lengthInBytes <= maxSafeBytes) {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        // If un-decodable but small, return with detected MIME
        return 'data:$detectedMime;base64,${base64Encode(bytes)}';
      }

      // If dimensions are already within maxDimension, retain existing bytes
      if (decoded.width <= maxDimension && decoded.height <= maxDimension) {
        return 'data:$detectedMime;base64,${base64Encode(bytes)}';
      }

      // Needs resizing to fit maxDimension
      final resizedBytes = _resizeAndEncode(
        decoded,
        maxDimension: maxDimension,
        quality: quality,
      );
      return 'data:image/jpeg;base64,${base64Encode(resizedBytes)}';
    }

    // Image exceeds safe byte threshold -> decode, downscale and compress
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Fallback if decode fails
      return 'data:$detectedMime;base64,${base64Encode(bytes)}';
    }

    final compressedBytes = _resizeAndEncode(
      decoded,
      maxDimension: maxDimension,
      quality: quality,
    );

    // If still over maxSafeBytes (rare), downscale further with lower quality
    if (compressedBytes.lengthInBytes > maxSafeBytes) {
      final fallbackBytes = _resizeAndEncode(
        decoded,
        maxDimension: (maxDimension * 0.75).round(),
        quality: (quality * 0.75).round(),
      );
      return 'data:image/jpeg;base64,${base64Encode(fallbackBytes)}';
    }

    return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
  }

  /// Downscales the decoded image proportionally to fit within [maxDimension]
  /// and encodes as JPEG with the given [quality].
  static Uint8List _resizeAndEncode(
    img.Image src, {
    required int maxDimension,
    required int quality,
  }) {
    int targetWidth = src.width;
    int targetHeight = src.height;

    if (targetWidth > maxDimension || targetHeight > maxDimension) {
      if (targetWidth >= targetHeight) {
        targetHeight = (targetHeight * maxDimension / targetWidth).round();
        targetWidth = maxDimension;
      } else {
        targetWidth = (targetWidth * maxDimension / targetHeight).round();
        targetHeight = maxDimension;
      }
    }

    final img.Image resized;
    if (targetWidth != src.width || targetHeight != src.height) {
      resized = img.copyResize(
        src,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = src;
    }

    final jpgBytes = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpgBytes);
  }
}
