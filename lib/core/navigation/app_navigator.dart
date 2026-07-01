import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';

/// Imperative navigation wrapper — used by services (socket) and notifiers.
class AppNavigator {
  AppNavigator(this._router);

  final GoRouter _router;

  String get currentLocation =>
      _router.routerDelegate.currentConfiguration.uri.path;

  bool get isOnCallScreen => AppRoutes.isCallRoute(currentLocation);

  bool get canPop => _router.canPop();

  void goSplash() => _router.go(AppRoutes.splash);

  void goLogin() => _router.go(AppRoutes.login);

  void goLanguage() => _router.go(AppRoutes.language);

  void goHome() => _router.go(AppRoutes.home);

  void goHistory() => _router.go(AppRoutes.history);

  void goWallet() => _router.go(AppRoutes.wallet);

  void goProfile() => _router.go(AppRoutes.profile);

  void goHostProfile(Map<String, dynamic> host) {
    _router.push(AppRoutes.hostProfile, extra: host);
  }

  void pushCalling(Map<String, dynamic> args) {
    _router.push(AppRoutes.calling, extra: args);
  }

  void pushIncomingCall(Map<String, dynamic> data) {
    if (isOnCallScreen) return;
    _router.push(AppRoutes.incomingCall, extra: data);
  }

  Future<T?> pushLanguage<T>({bool fromProfile = false}) {
    return _router.push<T>(AppRoutes.language, extra: fromProfile);
  }

  void replaceCalling(Map<String, dynamic> args) {
    _router.pushReplacement(AppRoutes.calling, extra: args);
  }

  void pop<T extends Object?>([T? result]) => _router.pop(result);

  void exitCallFlow() {
    if (canPop) {
      pop();
    }
    goHome();
  }

  void goShellTab(int index) {
    switch (index) {
      case 0:
        goHome();
      case 1:
        goHistory();
      case 2:
        goWallet();
      case 3:
        goProfile();
    }
  }
}

/// Slide + fade page transition for premium feel.
CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
