import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_base_url.dart';

Widget buildBusinessLogo(String path, {double size = 36}) {
  final resolved = resolveBusinessLogoUrl(path);
  if (resolved.isEmpty) {
    return Image.asset(
      'assets/icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  if (resolved.startsWith('http://') ||
      resolved.startsWith('https://') ||
      resolved.startsWith('blob:')) {
    return Image.network(
      resolved,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  if (resolved.startsWith('data:image')) {
    try {
      final commaIndex = resolved.indexOf(',');
      final base64String =
          commaIndex != -1 ? resolved.substring(commaIndex + 1) : resolved;
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return Image.asset(
        'assets/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
  }

  if (resolved.startsWith('assets/')) {
    return Image.asset(
      resolved,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  final file = File(resolved);
  if (file.existsSync()) {
    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  return Image.asset(
    'assets/icon.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}