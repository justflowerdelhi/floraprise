import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BotanicalSignature extends StatelessWidget {
  final double width;
  final double height;

  const BotanicalSignature({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SvgPicture.asset(
        'assets/logo/botanical_signature.svg',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
