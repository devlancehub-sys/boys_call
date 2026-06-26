import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'user_avatar.dart';

class GlowingAvatar extends StatelessWidget {
  const GlowingAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 36,
    this.glow = true,
    this.online = false,
    this.busy = false,
  });

  final String? avatarUrl;
  final String name;
  final double radius;
  final bool glow;
  final bool online;
  final bool busy;

  Color? get _presenceColor {
    if (busy) return AppColors.busy;
    if (online) return AppColors.online;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final presenceColor = _presenceColor;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: glow
            ? const LinearGradient(colors: [AppColors.accent, AppColors.accentLight])
            : null,
        border: glow ? null : Border.all(color: AppColors.border, width: 2),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.glow.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          UserAvatar(avatarUrl: avatarUrl, name: name, radius: radius),
          if (presenceColor != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: presenceColor,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
