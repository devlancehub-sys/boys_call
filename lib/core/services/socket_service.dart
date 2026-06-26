import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../navigation/app_navigator.dart';
import 'call_session_service.dart';
import 'presence_service.dart';

typedef SocketCallback = void Function(Map<String, dynamic> data);

class SocketService {
  SocketService({required CallSessionService callSession}) : _callSession = callSession;

  final CallSessionService _callSession;
  io.Socket? _socket;

  AppNavigator? navigator;
  PresenceService? presence;

  SocketCallback? onIncomingCall;
  SocketCallback? onCallAccepted;
  SocketCallback? onCallRejected;
  SocketCallback? onCallEnded;
  SocketCallback? onCallMissed;
  SocketCallback? onWalletUpdated;
  SocketCallback? onHostOnline;
  SocketCallback? onHostOffline;
  SocketCallback? onHostBusy;
  SocketCallback? onHostAvailable;

  bool get isConnected => _socket?.connected ?? false;

  /// Keeps an existing socket when possible — avoids dropping events mid-call.
  void ensureConnected(String token) {
    if (token.isEmpty) return;
    if (_socket?.connected == true) return;
    if (_socket != null) {
      _socket!.connect();
      return;
    }
    connect(token);
  }

  void connect(String token) {
    if (_socket?.connected == true) return;

    disconnect();

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] connected');
      presence?.isOnline.value = true;
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] disconnected');
      presence?.isOnline.value = false;
    });

    _socket!.onConnectError((data) => debugPrint('[Socket] connect error: $data'));

    _socket!.on('incoming_call', (data) {
      final map = _toMap(data);
      if (onIncomingCall != null) {
        onIncomingCall!(map);
      } else {
        _navigateIncomingCall(map);
      }
    });

    _socket!.on('call_ended', (data) {
      final map = _toMap(data);
      debugPrint(
        '[Socket] call_ended call_id=${map['call_id']} reason=${map['reason']}',
      );
      unawaited(_callSession.handleCallEnded(map));
    });

    _socket!.on('call_accepted', (data) => onCallAccepted?.call(_toMap(data)));
    _socket!.on('call_rejected', (data) => onCallRejected?.call(_toMap(data)));
    _socket!.on('call_missed', (data) => onCallMissed?.call(_toMap(data)));
    _socket!.on('wallet_updated', (data) => onWalletUpdated?.call(_toMap(data)));
    _socket!.on('host_online', (data) => onHostOnline?.call(_toMap(data)));
    _socket!.on('host_offline', (data) => onHostOffline?.call(_toMap(data)));
    _socket!.on('host_busy', (data) => onHostBusy?.call(_toMap(data)));
    _socket!.on('host_available', (data) => onHostAvailable?.call(_toMap(data)));

    _socket!.connect();
  }

  void _navigateIncomingCall(Map<String, dynamic> data) {
    if (navigator?.isOnCallScreen ?? false) return;
    navigator?.pushIncomingCall(data);
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void clearCallbacks() {
    onIncomingCall = null;
    onCallAccepted = null;
    onCallRejected = null;
    onCallMissed = null;
    onCallEnded = null;
    onWalletUpdated = null;
    onHostOnline = null;
    onHostOffline = null;
    onHostBusy = null;
    onHostAvailable = null;
  }
}
