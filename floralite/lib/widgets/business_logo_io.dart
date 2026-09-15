import 'dart:io';

import 'package:flutter/material.dart';

Widget buildBusinessLogo(String path, {double size = 36}) {
  final file = File(path.trim());
  if (path.trim().isNotEmpty && file.existsSync()) {
    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
  return Image.asset(
    'assets/icon.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}