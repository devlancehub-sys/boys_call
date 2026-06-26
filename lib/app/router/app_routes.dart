/// Central route path constants for GoRouter.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const language = '/language';
  static const home = '/home';
  static const history = '/history';
  static const wallet = '/wallet';
  static const profile = '/profile';
  static const hostProfile = '/host-profile';
  static const calling = '/calling';
  static const incomingCall = '/incoming-call';

  static bool isCallRoute(String location) {
    return location.startsWith(calling) || location.startsWith(incomingCall);
  }
}
