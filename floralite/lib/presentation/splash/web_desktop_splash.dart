import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'splash_logo.dart';

/// A desktop-first, premium splash screen widget for Floraprise Pro Cloud on Web.
class WebDesktopSplash extends StatefulWidget {
  const WebDesktopSplash({super.key});

  @override
  State<WebDesktopSplash> createState() => _WebDesktopSplashState();
}

class _WebDesktopSplashState extends State<WebDesktopSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600 || constraints.maxHeight < 550;
        final logoSize = isCompact ? 96.0 : 120.0;
        final titleSize = isCompact ? 26.0 : 32.0;
        final taglineSize = isCompact ? 13.0 : 15.0;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Deep botanical background with subtle warm radial gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.16),
                    radius: 0.95,
                    colors: [
                      Color(0xFF0D4638),
                      Color(0xFF062F25),
                      Color(0xFF041F19),
                    ],
                    stops: [0.0, 0.65, 1.0],
                  ),
                ),
              ),

              // Subtle botanical atmosphere in top-left
              Positioned(
                top: -30,
                left: -30,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.045,
                    child: Transform.rotate(
                      angle: -0.26,
                      child: SvgPicture.asset(
                        'assets/logo/botanical_signature.svg',
                        width: 320,
                        height: 240,
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle botanical atmosphere in bottom-right
              Positioned(
                bottom: -30,
                right: -30,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.045,
                    child: Transform.rotate(
                      angle: 2.88,
                      child: SvgPicture.asset(
                        'assets/logo/botanical_signature.svg',
                        width: 320,
                        height: 240,
                      ),
                    ),
                  ),
                ),
              ),

              // Centered brand composition
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Official Floraprise Logo Mark with soft ambient glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: logoSize * 1.3,
                              height: logoSize * 1.3,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0x35D8A020),
                                    Color(0x10D8A020),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: logoSize,
                              height: logoSize,
                              child: const FittedBox(
                                fit: BoxFit.contain,
                                child: SplashLogo(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 16 : 22),

                        // Brand Title
                        Text(
                          'Floraprise',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Colors.white,
                            fontFamily: '-apple-system',
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Edition Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0x1CE5B832),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x59E5B832),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_outlined,
                                size: 13,
                                color: Color(0xFFE5B832),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'PRO CLOUD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: Color(0xFFE5B832),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 12 : 16),

                        // Tagline
                        Text(
                          'Your Florist Business, Simplified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: taglineSize,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),

                        // Delicate Divider
                        Container(
                          width: 44,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.16),
                          margin: EdgeInsets.symmetric(vertical: isCompact ? 18 : 24),
                        ),

                        // Status Text
                        Text(
                          'Loading workspace…',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            color: Colors.white.withValues(alpha: 0.52),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Animated Loading Dots
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final progress = _pulseController.value;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (index) {
                                // Staggered pulsing dot animation
                                final dotOffset = (progress - (index * 0.25)) % 1.0;
                                final pulse = (dotOffset < 0.5)
                                    ? (dotOffset * 2.0)
                                    : ((1.0 - dotOffset) * 2.0);
                                final alpha = 0.25 + (0.7 * pulse);
                                final scale = 0.85 + (0.35 * pulse);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5B832).withValues(alpha: alpha),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
