import 'package:flutter/material.dart';

Widget buildBusinessLogo(String path, {double size = 36}) {
  return Image.asset(
    'assets/icon.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}