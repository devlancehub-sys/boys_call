import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator.center({super.key})
      : _center = true,
        color = AppColors.accent,
        size = null;

  const AppLoadingIndicator.inline({super.key, this.color = Colors.white, this.size = 22})
      : _center = false;

  final bool _center;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );

    return _center ? Center(child: indicator) : indicator;
  }
}
