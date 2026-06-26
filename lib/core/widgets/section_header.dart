import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader.primary({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  })  : _secondary = false;

  const SectionHeader.secondary({
    super.key,
    required this.title,
    this.padding = EdgeInsets.zero,
  })  : _secondary = true;

  final String title;
  final EdgeInsetsGeometry padding;
  final bool _secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          color: _secondary ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: _secondary ? 15 : 18,
          fontWeight: _secondary ? FontWeight.w400 : FontWeight.bold,
        ),
      ),
    );
  }
}
