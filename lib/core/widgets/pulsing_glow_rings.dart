import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PulsingGlowRings extends StatefulWidget {
  const PulsingGlowRings({
    super.key,
    required this.child,
    this.size = 160,
  });

  final Widget child;
  final double size;

  @override
  State<PulsingGlowRings> createState() => _PulsingGlowRingsState();
}

class _PulsingGlowRingsState extends State<PulsingGlowRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
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
        final pulse = 0.5 + _controller.value * 0.5;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(widget.size * 1.15, AppColors.glow.withValues(alpha: 0.15 * pulse)),
              _ring(widget.size * 0.95, AppColors.glow.withValues(alpha: 0.25 * pulse)),
              _ring(widget.size * 0.78, AppColors.accent.withValues(alpha: 0.12 * pulse)),
              Container(
                width: widget.size * 0.72,
                height: widget.size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.glow.withValues(alpha: 0.6 * pulse),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _ring(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}
