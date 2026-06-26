import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import 'widgets/animated_bottom_nav_bar.dart';

/// Main shell — IndexedStack via [StatefulNavigationShell] + animated bottom nav.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: navigationShell,
        ),
        bottomNavigationBar: AnimatedBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}
