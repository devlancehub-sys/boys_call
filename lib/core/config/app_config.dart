/// Production API server (boys app always uses live server).
class AppConfig {
  AppConfig._();

  static const String serverUrl = 'https://api.talkymate.in';

  static const String apiBaseUrl = '$serverUrl/api';
  static const String socketUrl = serverUrl;

  /// Production ZEGOCLOUD app id — used to pre-warm native SDK at startup.
  static const int zegoAppId = 2080383804;
}
