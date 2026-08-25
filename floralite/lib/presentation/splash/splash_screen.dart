import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/catalogue/catalogue_installer.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../managers/onboarding_manager.dart';
import '../../providers/auth_provider.dart';
import '../../screens/onboarding_flow_screen.dart';
import '../../services/scheduler_service.dart';
import 'floral_background.dart';
import 'splash_animation.dart';
import 'animated_loading_dots.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final OnboardingManager _onboardingManager = OnboardingManager();

  @override
  void initState() {
    super.initState();
    // Restore pending schedules after first frame to avoid blocking startup
    unawaited(SchedulerService.instance.restorePendingSchedules());
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      await _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    final completed = await _onboardingManager.isOnboardingCompleted();
    if (!mounted) return;

    if (!completed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
      );
      return;
    }

    await _ensureMasterCatalogue();
    if (!mounted) return;

    // Best-effort auth restore for cloud features; never block app entry.
    await context.read<AuthProvider>().initialize();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  Future<void> _ensureMasterCatalogue() async {
    final installer = CatalogueInstaller(
      productRepository: ProductRepository(),
      inventoryRepository: InventoryRepository(),
    );
    try {
      await installer.installStarterCatalogue(replaceLegacyDemoOnly: true);
    } catch (_) {
      // Best effort only: onboarding/data migration should not block entry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          FloralBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SplashAnimation(),
                  SizedBox(height: 60),
                  _LoadingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatefulWidget {
  const _LoadingSection();

  @override
  State<_LoadingSection> createState() => _LoadingSectionState();
}

class _LoadingSectionState extends State<_LoadingSection> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showText) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(
          'Preparing your workspace...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        const AnimatedLoadingDots(),
      ],
    );
  }
}
