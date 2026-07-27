import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _LeftLeaf(),
          _RightLeaf(),
          _Flower(),
          _LetterF(),
        ],
      ),
    );
  }
}

class _LeftLeaf extends StatelessWidget {
  const _LeftLeaf();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 40,
      child: SvgPicture.asset(
        'assets/logo/left_leaf.svg',
        width: 60,
        height: 60,
      ),
    );
  }
}

class _RightLeaf extends StatelessWidget {
  const _RightLeaf();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 40,
      child: SvgPicture.asset(
        'assets/logo/right_leaf.svg',
        width: 60,
        height: 60,
      ),
    );
  }
}

class _Flower extends StatelessWidget {
  const _Flower();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: SvgPicture.asset(
        'assets/logo/flower.svg',
        width: 100,
        height: 100,
      ),
    );
  }
}

class _LetterF extends StatelessWidget {
  const _LetterF();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: SvgPicture.asset(
        'assets/logo/letter_f.svg',
        width: 40,
        height: 50,
      ),
    );
  }
}
