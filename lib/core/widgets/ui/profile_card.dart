import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../glass_card.dart';
import '../glowing_avatar.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.online = false,
    this.busy = false,
  });

  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool online;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          GlowingAvatar(
            avatarUrl: avatarUrl,
            name: name,
            radius: 26,
            online: online,
            busy: busy,
            glow: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
