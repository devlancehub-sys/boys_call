import 'package:flutter/widgets.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'storage_service.dart';

/// Keeps user online only while the app is in the foreground with an active socket.
class PresenceService with WidgetsBindingObserver {
  PresenceService({
    required StorageService storage,
    required ApiService api,
    required SocketService socket,
  })  : _storage = storage,
        _api = api,
        _socket = socket;

  final StorageService _storage;
  final ApiService _api;
  final SocketService _socket;

  final ValueNotifier<bool> isOnline = ValueNotifier(false);
  bool _foreground = true;
  bool _keepAliveDuringCall = false;
  int _restoreEpoch = 0;

  Future<PresenceService> init() async {
    WidgetsBinding.instance.addObserver(this);
    _socket.presence = this;
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        if (_keepAliveDuringCall) {
          final token = _storage.accessToken;
          if (token != null && token.isNotEmpty && !_socket.isConnected) {
            _socket.ensureConnected(token);
          }
        } else {
          goOnline();
        }
        break;
      case AppLifecycleState.inactive:
        // Mic dialogs / overlays briefly enter inactive — do not mark offline here.
        if (_keepAliveDuringCall) return;
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _foreground = false;
        goOffline();
        break;
    }
  }

  Future<void> goOnline() async {
    if (!_foreground || !_storage.isLoggedIn) return;

    final token = _storage.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      await _api.put(ApiConstants.onlineStatus, data: {'is_online': true});
      _socket.ensureConnected(token);
      isOnline.value = true;
      debugPrint('[Presence] online (foreground)');
    } catch (e) {
      debugPrint('[Presence] goOnline failed: $e');
    }
  }

  Future<void> setCallActive(bool active) async {
    if (active) {
      _restoreEpoch++;
      _keepAliveDuringCall = true;
      final token = _storage.accessToken;
      if (token == null || token.isEmpty) return;

      if (!_socket.isConnected) {
        _socket.ensureConnected(token);
        debugPrint('[Presence] socket reconnected for active call');
      }
      return;
    }

    _keepAliveDuringCall = false;
  }

  /// Disconnect socket after a call, then reconnect for normal online presence.
  Future<void> restoreAfterCall() async {
    final epoch = ++_restoreEpoch;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (epoch != _restoreEpoch || _keepAliveDuringCall) return;

    _keepAliveDuringCall = false;
    _socket.disconnect();
    isOnline.value = false;

    if (!_foreground || !_storage.isLoggedIn) return;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (epoch != _restoreEpoch || _keepAliveDuringCall) return;
    await goOnline();
  }

  Future<void> goOffline() async {
    if (_keepAliveDuringCall) {
      debugPrint('[Presence] skipping offline — call active');
      return;
    }

    try {
      if (_storage.isLoggedIn) {
        await _api.put(ApiConstants.onlineStatus, data: {'is_online': false});
      }
    } catch (_) {}

    _socket.disconnect();
    isOnline.value = false;
    debugPrint('[Presence] offline (background/closed)');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    isOnline.dispose();
  }
}
