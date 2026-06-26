import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _loginDeviceIdKey = 'login_device_id';
  static const _callVibrateEnabledKey = 'call_vibrate_enabled';

  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  int? get userId => _prefs.getInt(_userIdKey);
  String? get userName => _prefs.getString(_userNameKey);
  String? get savedLoginDeviceId => _prefs.getString(_loginDeviceIdKey);

  bool get callVibrateEnabled =>
      _prefs.getBool(_callVibrateEnabledKey) ?? true;

  Future<void> setCallVibrateEnabled(bool value) async {
    await _prefs.setBool(_callVibrateEnabledKey, value);
  }

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  bool canAutoLogin(String currentDeviceId) {
    final name = userName;
    final savedDeviceId = savedLoginDeviceId;
    return name != null &&
        name.trim().length >= 2 &&
        savedDeviceId != null &&
        savedDeviceId.isNotEmpty &&
        savedDeviceId == currentDeviceId;
  }

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required int userId,
    String? name,
    String? deviceId,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setInt(_userIdKey, userId);
    if (name != null) await _prefs.setString(_userNameKey, name);
    if (deviceId != null) await _prefs.setString(_loginDeviceIdKey, deviceId);
  }

  void logAuthTokens() {
    debugPrint('[Storage] accessToken: ${accessToken ?? 'none'}');
    debugPrint('[Storage] refreshToken: ${refreshToken ?? 'none'}');
    debugPrint('[Storage] userId: $userId');
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userIdKey);
  }

  Future<void> clearAuth() async {
    await clearSession();
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_loginDeviceIdKey);
  }
}
