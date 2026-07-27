import 'package:flutter/material.dart';

class AnimatedLoadingDots extends StatefulWidget {
  const AnimatedLoadingDots({super.key});

  @override
  State<AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = (value - index).abs() < 0.5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Dot(isActive: isActive),
            );
          }),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;

  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
