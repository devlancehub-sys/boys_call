import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_brand_icon.dart';
import 'glowing_avatar.dart';
import 'pulsing_glow_rings.dart';

class OrbitalRecommendedCarousel extends StatefulWidget {
  const OrbitalRecommendedCarousel({
    super.key,
    required this.hosts,
    required this.onHostTap,
    this.height = 300,
    this.orbitRadius = 108,
    this.maxOrbitHosts = 8,
  });

  final List<Map<String, dynamic>> hosts;
  final void Function(Map<String, dynamic> host) onHostTap;
  final double height;
  final double orbitRadius;
  final int maxOrbitHosts;

  @override
  State<OrbitalRecommendedCarousel> createState() => _OrbitalRecommendedCarouselState();
}

class _OrbitalRecommendedCarouselState extends State<OrbitalRecommendedCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbitHosts = widget.hosts.take(widget.maxOrbitHosts).toList();
    if (orbitHosts.isEmpty) {
      return widget.height.isFinite
          ? SizedBox(height: widget.height)
          : const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = widget.height.isFinite ? widget.height : constraints.maxHeight;
        final radius = widget.orbitRadius.clamp(80.0, height * 0.38);

        return SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _orbitController,
            builder: (context, _) {
              final rotation = _orbitController.value * math.pi * 2;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _RadarRings(size: radius * 2.35),
                  ...List.generate(orbitHosts.length, (index) {
                    final host = orbitHosts[index];
                    final name = host['name']?.toString() ?? 'Host';
                    final rawOnline = host['is_online'];
                    final isOnline =
                        rawOnline == 1 || rawOnline == true || rawOnline == '1';
                    final rawBusy = host['is_busy'];
                    final isBusy =
                        rawBusy == 1 || rawBusy == true || rawBusy == '1';
                    final angle = rotation + (index / orbitHosts.length) * math.pi * 2;
                    final dx = math.cos(angle) * radius;
                    final dy = math.sin(angle) * radius;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: GestureDetector(
                        onTap: () => widget.onHostTap(host),
                        child: _OrbitHostAvatar(
                          avatarUrl: host['avatar_url']?.toString(),
                          name: name,
                          isOnline: isOnline,
                          isBusy: isBusy,
                        ),
                      ),
                    );
                  }),
                  PulsingGlowRings(
                    size: 130,
                    child: const AppBrandIcon(size: 92, iconScale: 0.88),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RadarRings extends StatelessWidget {
  const _RadarRings({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _ring(size * 1.0, 0.22),
        _ring(size * 0.78, 0.16),
        _ring(size * 0.56, 0.10),
      ],
    );
  }

  Widget _ring(double diameter, double opacity) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent.withValues(alpha: opacity), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.glow.withValues(alpha: opacity * 0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _OrbitHostAvatar extends StatelessWidget {
  const _OrbitHostAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isOnline,
    required this.isBusy,
  });

  final String? avatarUrl;
  final String name;
  final bool isOnline;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlowingAvatar(
          avatarUrl: avatarUrl,
          name: name,
          radius: 28,
          glow: true,
          online: isOnline,
          busy: isBusy,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
