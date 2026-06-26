import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FloatingHearts extends StatefulWidget {
  const FloatingHearts({super.key, this.count = 8});

  final int count;

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_HeartParticle> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random(42);
    _particles = List.generate(widget.count, (i) {
      return _HeartParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 10 + random.nextDouble() * 14,
        delay: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 0.5,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _HeartsPainter(
            progress: _controller.value,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _HeartParticle {
  const _HeartParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.speed,
  });

  final double x;
  final double y;
  final double size;
  final double delay;
  final double speed;
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter({required this.progress, required this.particles});

  final double progress;
  final List<_HeartParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.delay) % 1.0;
      final floatY = size.height * (1 - t) + p.y * 40;
      final floatX = size.width * p.x + sin(t * pi * 2) * 12;
      final opacity = (sin(t * pi) * 0.45 + 0.15).clamp(0.0, 0.6);

      final paint = Paint()
        ..color = AppColors.accent.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      _drawHeart(canvas, Offset(floatX, floatY), p.size, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    path.moveTo(x, y + size * 0.3);
    path.cubicTo(x - size * 0.5, y - size * 0.2, x - size * 0.5, y + size * 0.4, x, y + size * 0.8);
    path.cubicTo(x + size * 0.5, y + size * 0.4, x + size * 0.5, y - size * 0.2, x, y + size * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
