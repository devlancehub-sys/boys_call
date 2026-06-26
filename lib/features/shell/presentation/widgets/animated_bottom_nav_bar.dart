import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/animations/scale_tap.dart';

/// Premium animated bottom navigation — scale + fade on tab switch.
class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavMeta(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavMeta(Icons.history_outlined, Icons.history_rounded, 'History'),
    _NavMeta(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Wallet'),
    _NavMeta(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
          boxShadow: [
            BoxShadow(
              color: AppColors.glow.withValues(alpha: 0.08),
              blurRadius: 20.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                return _AnimatedNavItem(
                  meta: _items[index],
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavMeta {
  const _NavMeta(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _AnimatedNavItem extends StatelessWidget {
  const _AnimatedNavItem({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final _NavMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? meta.activeIcon : meta.icon,
                color: selected ? AppColors.accent : AppColors.textMuted,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textMuted,
                fontSize: 11.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(meta.label),
            ),
          ],
        ),
      ),
    );
  }
}
