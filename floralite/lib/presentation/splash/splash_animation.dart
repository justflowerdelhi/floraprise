import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashAnimation extends StatefulWidget {
  const SplashAnimation({super.key});

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _leftLeafAnimation;
  late Animation<double> _rightLeafAnimation;
  late Animation<double> _flowerAnimation;
  late Animation<double> _letterFAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _wordmarkAnimation;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _leftLeafAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 400,
      ),
    ]).animate(_controller);

    _rightLeafAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 500,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 400,
      ),
    ]).animate(_controller);

    _flowerAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 900,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.2).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 250,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 250,
      ),
    ]).animate(_controller);

    _letterFAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 1400,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 300,
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 1700,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.15).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 350,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 350,
      ),
    ]).animate(_controller);

    _wordmarkAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 2000,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 500,
      ),
    ]).animate(_controller);

    _taglineAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 2200,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 400,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedLogo(
              leftLeafProgress: _leftLeafAnimation.value,
              rightLeafProgress: _rightLeafAnimation.value,
              flowerProgress: _flowerAnimation.value,
              letterFProgress: _letterFAnimation.value,
              glowProgress: _glowAnimation.value,
            ),
            const SizedBox(height: 40),
            _Wordmark(progress: _wordmarkAnimation.value),
            const SizedBox(height: 8),
            _Tagline(progress: _taglineAnimation.value),
          ],
        );
      },
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final double leftLeafProgress;
  final double rightLeafProgress;
  final double flowerProgress;
  final double letterFProgress;
  final double glowProgress;

  const _AnimatedLogo({
    required this.leftLeafProgress,
    required this.rightLeafProgress,
    required this.flowerProgress,
    required this.letterFProgress,
    required this.glowProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Glow(progress: glowProgress),
          _AnimatedLeftLeaf(progress: leftLeafProgress),
          _AnimatedRightLeaf(progress: rightLeafProgress),
          _AnimatedFlower(progress: flowerProgress),
          _AnimatedLetterF(progress: letterFProgress),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double progress;

  const _Glow({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFD8A020).withValues(alpha: 0.3),
              const Color(0xFFD8A020).withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLeftLeaf extends StatelessWidget {
  final double progress;

  const _AnimatedLeftLeaf({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-40 * (1 - progress), 40 * (1 - progress)),
      child: Transform.scale(
        scale: 0.3 + (0.7 * progress),
        child: Opacity(
          opacity: progress,
          child: SvgPicture.asset(
            'assets/logo/left_leaf.svg',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }
}

class _AnimatedRightLeaf extends StatelessWidget {
  final double progress;

  const _AnimatedRightLeaf({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(40 * (1 - progress), 40 * (1 - progress)),
      child: Transform.scale(
        scale: 0.3 + (0.7 * progress),
        child: Opacity(
          opacity: progress,
          child: SvgPicture.asset(
            'assets/logo/right_leaf.svg',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }
}

class _AnimatedFlower extends StatelessWidget {
  final double progress;

  const _AnimatedFlower({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: progress,
      child: SvgPicture.asset(
        'assets/logo/flower.svg',
        width: 100,
        height: 100,
      ),
    );
  }
}

class _AnimatedLetterF extends StatelessWidget {
  final double progress;

  const _AnimatedLetterF({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 20 * (1 - progress)),
      child: Opacity(
        opacity: progress,
        child: SvgPicture.asset(
          'assets/logo/letter_f.svg',
          width: 40,
          height: 50,
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double progress;

  const _Wordmark({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 20 * (1 - progress)),
      child: Opacity(
        opacity: progress,
        child: const Text(
          'Floraprise',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  final double progress;

  const _Tagline({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Text(
        'Powering Modern Florists',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.75),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
