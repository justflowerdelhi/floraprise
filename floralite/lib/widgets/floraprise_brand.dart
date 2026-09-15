import 'package:flutter/material.dart';

class FlorapriseBrand extends StatelessWidget {
  const FlorapriseBrand({
    super.key,
    this.iconSize = 28,
    this.wordmarkHeight = 22,
  });

  final double iconSize;
  final double wordmarkHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icon.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: iconSize == 28 ? 8 : 10),
        Image.asset(
          'assets/floraprise-title.png',
          height: wordmarkHeight,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}