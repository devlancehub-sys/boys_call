import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/utils/zego_plugin_check.dart';

final splashProvider = NotifierProvider<SplashNotifier, void>(SplashNotifier.new);

class SplashNotifier extends Notifier<void> {
  late final StorageService _storage;
  late final ApiService _api;
  late final DeviceService _device;
  late final PresenceService _presence;
  late final AppNavigator _navigator;

  @override
  void build() {
    _storage = ref.read(storageServiceProvider);
    _api = ref.read(apiServiceProvider);
    _device = ref.read(deviceServiceProvider);
    _presence = ref.read(presenceServiceProvider);
    _navigator = ref.read(appNavigatorProvider);
  }

  Future<void> bootstrap() async {
    unawaited(prefetchMicrophonePermissionOnLaunch());
    unawaited(warmUpZegoPlugin());
    unawaited(_prefetchZegoEngine());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (!_storage.isLoggedIn) {
        if (_storage.canAutoLogin(_device.deviceId)) {
          final autoLoggedIn = await _tryAutoLogin().timeout(const Duration(seconds: 8));
          if (autoLoggedIn) return;
        }
        _goLogin();
        return;
      }

      await _resumeSession().timeout(const Duration(seconds: 6));
    } on TimeoutException {
      await _storage.clearSession();
      if (_storage.canAutoLogin(_device.deviceId)) {
        final autoLoggedIn = await _tryAutoLogin().timeout(const Duration(seconds: 8));
        if (autoLoggedIn) return;
      }
      _goLogin();
    } catch (_) {
      await _storage.clearSession();
      if (_storage.canAutoLogin(_device.deviceId)) {
        final autoLoggedIn = await _tryAutoLogin().timeout(const Duration(seconds: 8));
        if (autoLoggedIn) return;
      }
      _goLogin();
    }
  }

  Future<bool> _tryAutoLogin() async {
    final name = _storage.userName?.trim();
    if (name == null || name.length < 2) return false;

    try {
      await _device.ensureFcmReady();
      final res = await _api.postAuth(ApiConstants.quickLogin, data: {
        ..._device.loginFields,
        'name': name,
      });

      final data = res['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      await _storage.saveAuth(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: user['id'] as int,
        name: user['name'] as String? ?? name,
        deviceId: _device.deviceId,
      );

      final profileRes = await _api.get(ApiConstants.profile);
      final profile = profileRes['data'] as Map<String, dynamic>?;
      final languages = profile?['languages'] as List? ?? [];

      if (languages.isEmpty) {
        _navigator.goLanguage();
      } else {
        _navigator.goHome();
      }

      unawaited(_presence.goOnline());
      unawaited(_device.syncWithServer());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _resumeSession() async {
    final profileRes = await _api.get(ApiConstants.profile);
    final profile = profileRes['data'] as Map<String, dynamic>?;
    final languages = profile?['languages'] as List? ?? [];

    if (languages.isEmpty) {
      _navigator.goLanguage();
    } else {
      _navigator.goHome();
    }

    unawaited(_presence.goOnline());
    unawaited(_device.syncWithServer());
  }

  void _goLogin() => _navigator.goLogin();

  Future<void> _prefetchZegoEngine() async {
    try {
      await ref.read(zegoCallServiceProvider).ensureEngine(AppConfig.zegoAppId);
    } catch (e) {
      debugPrint('[Splash] Zego engine pre-warm skipped: $e');
    }
  }
}
