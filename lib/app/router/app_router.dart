import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_navigator.dart';
import '../../modules/auth/language/language_view.dart';
import '../../modules/auth/login/login_view.dart';
import '../../modules/calling/calling_view.dart';
import '../../modules/host_profile/host_profile_view.dart';
import '../../modules/incoming_call/incoming_call_view.dart';
import '../../modules/splash/splash_view.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/call_history/presentation/call_history_page.dart';
import '../../features/wallet/presentation/wallet_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SplashView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const LoginView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.language,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: LanguageView(fromProfile: state.extra == true),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CallHistoryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wallet,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const WalletPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.hostProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: HostProfileView(host: state.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: AppRoutes.calling,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: CallingView(args: state.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: AppRoutes.incomingCall,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: IncomingCallView(callData: state.extra as Map<String, dynamic>?),
        ),
      ),
    ],
  );
}
