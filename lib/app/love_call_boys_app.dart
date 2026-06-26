import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart';

import '../core/messaging/app_messenger.dart';
import 'theme/app_theme.dart';

/// Root app widget — used by [main] and widget tests.
class LoveCallBoysApp extends StatelessWidget {
  const LoveCallBoysApp({
    super.key,
    required this.router,
    this.overrides = const [],
  });

  final GoRouter router;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp.router(
          title: 'Love Call',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey,
          theme: AppTheme.dark,
        ),
      ),
    );
  }
}
