import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_base_url.dart';

class SafePlatformImageView extends StatelessWidget {
  const SafePlatformImageView({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Icons.photo_library_outlined,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.fallbackWidget,
  });

  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;
  final IconData errorIcon;
  final Widget? fallbackWidget;

  @override
  Widget build(BuildContext context) {
    final raw = imagePath?.trim();
    if (raw == null || raw.isEmpty) {
      return fallbackWidget ??
          Center(
            child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade400),
          );
    }

    final path = resolveBusinessLogoUrl(raw);
    if (path.isEmpty) {
      return fallbackWidget ??
          Center(
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
        errorBuilder: (context, error, stackTrace) =>
            fallbackWidget ??
            Center(
              child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
            ),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final commaIndex = path.indexOf(',');
        final base64String =
            commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              fallbackWidget ??
              Center(
                child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
              ),
        );
      } catch (_) {
        return fallbackWidget ??
            Center(
              child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
            );
      }
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            fallbackWidget ??
            Center(
              child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
            ),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        io.File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            fallbackWidget ??
            Center(
              child: Icon(errorIcon, size: 40, color: Colors.grey.shade400),
            ),
      );
    }

    return fallbackWidget ??
        Center(
          child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade400),
        );
  }
}
