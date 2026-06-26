import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AnimatedCallIcon extends StatefulWidget {
  const AnimatedCallIcon({
    super.key,
    this.size = 36,
    this.active = true,
    this.phaseOffset = 0,
  });

  final double size;
  final bool active;
  final double phaseOffset;

  @override
  State<AnimatedCallIcon> createState() => _AnimatedCallIconState();
}

class _AnimatedCallIconState extends State<AnimatedCallIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCallIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return _iconBody(glow: 0.2, scale: 1, ripple: 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = (_controller.value + widget.phaseOffset) % 1.0;
        final pulse = (1 + (0.5 * (1 - (2 * t - 1).abs()))) / 1.5;
        final glow = 0.35 + pulse * 0.65;
        final scale = 0.92 + pulse * 0.12;
        final ripple = t;

        return _iconBody(glow: glow, scale: scale, ripple: ripple);
      },
    );
  }

  Widget _iconBody({required double glow, required double scale, required double ripple}) {
    final iconSize = widget.size * 0.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active && ripple > 0)
            Transform.scale(
              scale: 0.8 + ripple * 0.9,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: (1 - ripple) * 0.55),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          if (widget.active && ripple > 0)
            Transform.scale(
              scale: 0.6 + ripple * 0.7,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: (1 - ripple) * 0.18),
                ),
              ),
            ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size * 0.88,
              height: widget.size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.25 + glow * 0.2),
                    AppColors.accentLight.withValues(alpha: 0.15 + glow * 0.15),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: glow * 0.7),
                    blurRadius: 10 + glow * 14,
                    spreadRadius: glow * 3,
                  ),
                  BoxShadow(
                    color: AppColors.glow.withValues(alpha: glow * 0.5),
                    blurRadius: 18 + glow * 10,
                    spreadRadius: glow * 1.5,
                  ),
                ],
              ),
              child: Icon(
                Icons.call_rounded,
                color: Color.lerp(AppColors.accentLight, Colors.white, glow * 0.6),
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
