import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/floating_hearts.dart';
import '../../core/widgets/brand_title_text.dart';
import '../../core/widgets/pulsing_glow_rings.dart';
import 'splash_notifier.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      body: _SplashAnimatedBody(),
    );
  }
}

class _SplashAnimatedBody extends StatefulWidget {
  const _SplashAnimatedBody();

  @override
  State<_SplashAnimatedBody> createState() => _SplashAnimatedBodyState();
}

class _SplashAnimatedBodyState extends State<_SplashAnimatedBody> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleIn = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.screenBackgroundAlt),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FloatingHearts(count: 10),
          Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: PulsingGlowRings(
                    size: 180,
                    child: const AppBrandIcon(size: 130),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    const BrandTitleText(fontSize: 42),
                    const SizedBox(height: 10),
                    Text(
                      'Where voice connects hearts',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }
}
