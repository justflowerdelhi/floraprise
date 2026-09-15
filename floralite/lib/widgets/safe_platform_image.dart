import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SafePlatformImageView extends StatelessWidget {
  const SafePlatformImageView({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Icons.photo_library_outlined,
    this.errorIcon = Icons.image_not_supported_outlined,
  });

  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;
  final IconData errorIcon;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return Center(
        child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade400),
      );
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
        ),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final commaIndex = path.indexOf(',');
        final base64String = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
          ),
        );
      } catch (_) {
        return Center(
          child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
        );
      }
    }

    if (!kIsWeb) {
      return Image.file(
        io.File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
        ),
      );
    }

    return Center(
      child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade400),
    );
  }
}
