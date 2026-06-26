import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/call_session_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/zego_call_service.dart';
import '../../core/services/zego_join_result.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/utils/voice_connect_config.dart';
import '../home/home_notifier.dart';

enum CallStatus { ringing, connected, ended }

class CallingState {
  const CallingState({
    this.status = CallStatus.ringing,
    this.durationSeconds = 0,
    this.hostName = 'Host',
    this.hostAvatarUrl,
    this.ratePerMinute = 0,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isEnding = false,
    this.voiceConnected = false,
    this.voiceConnecting = false,
    this.voiceAutoRetrying = false,
    this.voiceLastError,
  });

  final CallStatus status;
  final int durationSeconds;
  final String hostName;
  final String? hostAvatarUrl;
  final double ratePerMinute;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isEnding;
  final bool voiceConnected;
  final bool voiceConnecting;
  final bool voiceAutoRetrying;
  final String? voiceLastError;

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  CallingState copyWith({
    CallStatus? status,
    int? durationSeconds,
    String? hostName,
    String? hostAvatarUrl,
    double? ratePerMinute,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isEnding,
    bool? voiceConnected,
    bool? voiceConnecting,
    bool? voiceAutoRetrying,
    String? voiceLastError,
  }) {
    return CallingState(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      ratePerMinute: ratePerMinute ?? this.ratePerMinute,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isEnding: isEnding ?? this.isEnding,
      voiceConnected: voiceConnected ?? this.voiceConnected,
      voiceConnecting: voiceConnecting ?? this.voiceConnecting,
      voiceAutoRetrying: voiceAutoRetrying ?? this.voiceAutoRetrying,
      voiceLastError: voiceLastError ?? this.voiceLastError,
    );
  }
}

final callingProvider = NotifierProvider<CallingNotifier, CallingState>(CallingNotifier.new);

class CallingNotifier extends Notifier<CallingState> {
  late final ApiService _api;
  late final SocketService _socket;
  late final CallSessionService _callSession;
  late final ZegoCallService _zego;
  late final StorageService _storage;
  late final PresenceService _presence;
  late final AppNavigator _navigator;

  int? callId;
  String? roomId;
  int? zegoAppId;
  String? zegoToken;
  Timer? _timer;
  int _backgroundRetryGen = 0;
  String? _lastVoiceError;
  bool _hasEnded = false;
  bool _wasConnected = false;
  bool _callAccepted = false;
  bool _zegoJoined = false;
  int _session = 0;
  bool _disposed = false;
  int _socketDownSince = 0;

  @override
  CallingState build() {
    _api = ref.read(apiServiceProvider);
    _socket = ref.read(socketServiceProvider);
    _callSession = ref.read(callSessionServiceProvider);
    _zego = ref.read(zegoCallServiceProvider);
    _storage = ref.read(storageServiceProvider);
    _presence = ref.read(presenceServiceProvider);
    _navigator = ref.read(appNavigatorProvider);

    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      if (_hasEnded || !_wasConnected) {
        _callSession.unregister();
      }
      _clearSocketHandlers();
    });

    return const CallingState();
  }

  /// Register handlers before navigation so early socket events are not missed.
  void registerOutgoingCall(int id) {
    callId = id;
    _callSession.register(id, _handleRemoteEnd);
    unawaited(_presence.setCallActive(true));
  }

  void init(Map<String, dynamic>? args) {
    _session++;
    final session = _session;
    unawaited(_initSession(session, args: args));
  }

  Future<void> _initSession(int session, {Map<String, dynamic>? args}) async {
    _clearSocketHandlers();
    await _resetLocalCallState();
    if (session != _session) return;

    final data = args ?? {};
    callId = JsonParse.toInt(data['call_id']);
    if (callId != null && callId! <= 0) callId = null;
    roomId = data['room_id']?.toString();
    zegoToken = data['zego_token']?.toString();
    zegoAppId = JsonParse.toInt(data['zego_app_id']);

    state = CallingState(
      hostName: data['host_name']?.toString() ?? 'Host',
      hostAvatarUrl: data['host_avatar_url']?.toString(),
      ratePerMinute: JsonParse.toDouble(data['rate_per_minute']),
    );

    _socket.onCallAccepted = _onCallAccepted;
    _socket.onCallRejected = _onCallRejected;
    _socket.onCallMissed = _onCallMissed;

    if (callId != null) {
      _callSession.register(callId!, _handleRemoteEnd);
      unawaited(_presence.setCallActive(true));
    }

    final alreadyConnected = data['already_connected'] as bool? ?? false;
    if (alreadyConnected) {
      _callAccepted = true;
      _markCallActive();
      await _connectVoiceWithRetry(session);
    }
  }

  Future<void> _resetLocalCallState() async {
    _hasEnded = false;
    _wasConnected = false;
    _callAccepted = false;
    _socketDownSince = 0;
    state = state.copyWith(voiceConnected: false, voiceConnecting: false, voiceLastError: null);
    if (_zegoJoined) {
      await _zego.leaveRoom();
      _zegoJoined = false;
    }
  }

  void _markCallActive() {
    _wasConnected = true;
    state = state.copyWith(status: CallStatus.connected);
    _startTimer();
  }

  Future<void> retryVoice() => _connectVoiceWithRetry(_session);

  Future<void> _connectVoiceWithRetry(int session) async {
    if (_hasEnded || state.voiceConnecting || state.voiceConnected) return;
    if (!_callAccepted && !_wasConnected) return;

    _stopBackgroundVoiceRetry();
    state = state.copyWith(voiceConnecting: true);
    try {
      for (var attempt = 1; attempt <= VoiceConnectConfig.maxAttempts; attempt++) {
        if (_hasEnded || session != _session) return;

        await Future<void>.delayed(
          Duration(milliseconds: VoiceConnectConfig.delayBeforeAttempt(attempt)),
        );
        if (_hasEnded || session != _session) return;

        final joined = await _connectZego(attempt: attempt);
        if (session != _session) {
          await _zego.leaveRoom();
          _zegoJoined = false;
          return;
        }
        if (joined) {
          _stopBackgroundVoiceRetry();
          state = state.copyWith(voiceConnected: true, voiceLastError: null);
          return;
        }
      }

      state = state.copyWith(voiceConnected: false);
      _showVoiceSnack(
        'Voice not connected',
        _lastVoiceError ?? 'All auto-retries failed. Tap Retry Voice.',
      );
      _startBackgroundVoiceRetry(session);
    } finally {
      if (!_hasEnded && session == _session && !state.voiceAutoRetrying) {
        state = state.copyWith(voiceConnecting: false);
      }
    }
  }

  void _startBackgroundVoiceRetry(int session) {
    final gen = ++_backgroundRetryGen;
    state = state.copyWith(voiceAutoRetrying: true, voiceConnecting: true);
    unawaited(_backgroundVoiceRetryLoop(session, gen));
  }

  Future<void> _backgroundVoiceRetryLoop(int session, int gen) async {
    while (
        !_hasEnded &&
        session == _session &&
        gen == _backgroundRetryGen &&
        !state.voiceConnected) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_hasEnded || session != _session || gen != _backgroundRetryGen) return;

      final joined = await _connectZego(attemptLabel: 'background');
      if (joined && session == _session && !_hasEnded) {
        state = state.copyWith(
          voiceConnected: true,
          voiceConnecting: false,
          voiceAutoRetrying: false,
          voiceLastError: null,
        );
        return;
      }
    }

    if (gen == _backgroundRetryGen && !_hasEnded && session == _session) {
      _showVoiceSnack(
        'Voice still failing',
        _lastVoiceError ?? 'Background retries stopped. Tap Retry Voice.',
      );
      state = state.copyWith(voiceConnecting: false, voiceAutoRetrying: false);
    }
  }

  void _stopBackgroundVoiceRetry() {
    _backgroundRetryGen++;
    state = state.copyWith(voiceAutoRetrying: false);
  }

  bool _matchesCall(Map<String, dynamic> data) {
    if (callId == null) return false;
    return _callSession.matchesCallId(data, callId!);
  }

  void _onCallAccepted(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    if (_zegoJoined || _wasConnected) return;

    zegoToken = data['zego_token']?.toString() ?? zegoToken;
    final appId = JsonParse.toInt(data['zego_app_id']);
    if (appId > 0) zegoAppId = appId;
    roomId = data['room_id']?.toString() ?? roomId;

    _callAccepted = true;
    _markCallActive();
    unawaited(_connectVoiceWithRetry(_session));
  }

  void _onCallRejected(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    unawaited(_finishCall('Call rejected'));
  }

  void _onCallMissed(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    unawaited(_finishCall('No answer — user did not pick up'));
  }

  Future<void> _handleRemoteEnd(Map<String, dynamic> data) async {
    if (_hasEnded) return;
    debugPrint('[Calling] remote end call_id=${data['call_id']} reason=${data['reason']}');
    await _finishCall('Call ended', billing: data);
    unawaited(_refreshWalletBalance());
  }

  Future<void> _refreshWalletBalance() async {
    try {
      await ref.read(homeProvider.notifier).loadBalance();
      await ref.read(homeProvider.notifier).loadOnlineHosts();
      await ref.read(homeProvider.notifier).loadAllHosts();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _requestCallEnd() async {
    if (callId == null || !_wasConnected) return null;

    final res = await _api
        .post(ApiConstants.callEnd(callId!))
        .timeout(const Duration(seconds: 12));
    return JsonParse.toMap(res['data']);
  }

  Future<void> _abortServerCall() async {
    if (callId == null) return;

    try {
      await _api.post(ApiConstants.callEnd(callId!));
      return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 400 && status != 404) rethrow;
    }

    try {
      await _api.post(ApiConstants.callReject(callId!));
    } catch (_) {}
  }

  void _showBillingMessage(Map<String, dynamic> data) {
    final deducted = JsonParse.toDouble(data['amount_deducted']);
    final minutes = data['billable_minutes'] ?? 1;
    AppMessenger.show(
      'Call ended',
      '₹${deducted.toStringAsFixed(2)} deducted ($minutes min)',
      duration: const Duration(seconds: 4),
    );
  }

  void _showVoiceSnack(String title, String message) {
    final detail = message.trim();
    if (detail.isEmpty) return;
    _lastVoiceError = detail;
    state = state.copyWith(voiceLastError: detail);
    AppMessenger.show(title, detail, duration: const Duration(seconds: 5));
  }

  bool _hasVoiceCredentials() {
    return roomId != null &&
        roomId!.isNotEmpty &&
        zegoToken != null &&
        zegoToken!.isNotEmpty &&
        zegoAppId != null &&
        zegoAppId! > 0;
  }

  Future<bool> _fetchVoiceJoinFromBackend() async {
    if (callId == null) return false;
    try {
      final res = await _api.post(ApiConstants.callJoinVoice(callId!));
      final data = JsonParse.toMap(res['data']);
      if (data == null) {
        if (!_hasVoiceCredentials()) {
          _showVoiceSnack('join-voice', 'Server returned empty data');
        }
        return _hasVoiceCredentials();
      }

      roomId = data['room_id']?.toString() ?? roomId;
      zegoToken = data['zego_token']?.toString();
      final appId = JsonParse.toInt(data['zego_app_id']);
      if (appId > 0) zegoAppId = appId;

      if (!_hasVoiceCredentials()) {
        _showVoiceSnack('join-voice', 'Missing room_id, token, or zego_app_id in response');
      }
      return _hasVoiceCredentials();
    } catch (e) {
      debugPrint('[Calling] join-voice failed: $e');
      final apiError = _api.errorMessage(e);
      if (_hasVoiceCredentials()) {
        _showVoiceSnack(
          'join-voice (fallback)',
          'API failed ($apiError) — using accept token. room=$roomId',
        );
        return true;
      }
      _showVoiceSnack('join-voice', apiError);
      return false;
    }
  }

  Future<bool> _connectZego({int? attempt, String? attemptLabel}) async {
    if (callId == null) return false;

    final attemptTag = attemptLabel ?? (attempt != null ? 'try $attempt' : 'connect');

    if (!await _fetchVoiceJoinFromBackend()) {
      return false;
    }

    final userId = _storage.userId;
    if (userId == null) {
      _showVoiceSnack('Zego ($attemptTag)', 'User ID missing — sign in again');
      return false;
    }

    if (zegoAppId != null && zegoAppId! > 0) {
      try {
        await _zego.ensureEngine(zegoAppId!);
      } catch (e) {
        debugPrint('[Calling] engine pre-warm: $e');
        _showVoiceSnack('Zego engine', e.toString());
        return false;
      }
    }

    try {
      final result = await _zego.joinRoom(
        roomId: roomId!,
        userId: '$userId',
        userName: _storage.userName ?? 'User$userId',
        token: zegoToken,
        appId: zegoAppId!,
      );
      if (result.ok) {
        _zegoJoined = true;
        await _presence.setCallActive(true);
        AppMessenger.show('Voice connected', 'Room $roomId', duration: const Duration(seconds: 2));
        return true;
      }

      debugPrint('[Calling] Zego join failed: ${result.userMessage}');
      _showVoiceSnack('Zego ($attemptTag)', '${result.userMessage} | room=$roomId user=$userId');
      if (result.failure == ZegoJoinFailure.micPermanentlyDenied) {
        await openMicrophoneSettings();
      }
      return false;
    } catch (e) {
      debugPrint('[Calling] Zego join exception: $e');
      _showVoiceSnack('Zego ($attemptTag)', e.toString());
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(durationSeconds: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      _ensureSocketDuringCall();
    });
  }

  void _ensureSocketDuringCall() {
    if (!_wasConnected && !_callAccepted) return;
    if (_hasEnded) return;

    if (_socket.isConnected) {
      _socketDownSince = 0;
      return;
    }

    _socketDownSince++;
    if (_socketDownSince < 3) return;

    final token = _storage.accessToken;
    if (token == null || token.isEmpty) return;
    _socket.ensureConnected(token);
  }

  void _clearSocketHandlers() {
    _socket.onCallAccepted = null;
    _socket.onCallRejected = null;
    _socket.onCallMissed = null;
  }

  void dismissCall() {
    if (!_hasEnded) {
      _hasEnded = true;
      _timer?.cancel();
    }
    state = state.copyWith(status: CallStatus.ended, isEnding: false);
    _navigator.exitCallFlow();
  }

  Future<void> endCall({String? message}) async {
    if (_hasEnded || state.status == CallStatus.ended) {
      dismissCall();
      return;
    }
    if (state.isEnding) return;
    state = state.copyWith(isEnding: true);

    Map<String, dynamic>? billing;
    try {
      if (state.status == CallStatus.connected && callId != null) {
        billing = await _requestCallEnd();
        if (billing != null) {
          _showBillingMessage(billing);
        }
      } else if (callId != null &&
          (state.status == CallStatus.ringing || _callAccepted) &&
          state.status != CallStatus.connected) {
        if (_callAccepted) {
          await _api.post(ApiConstants.callEnd(callId!));
          message ??= 'Call ended';
        } else {
          await _api.post(ApiConstants.callReject(callId!));
          message ??= 'Call cancelled';
        }
      }
    } catch (e) {
      try {
        await _abortServerCall();
      } catch (_) {}
      final status = e is DioException ? e.response?.statusCode : null;
      if (status != 400 && status != 404) {
        AppMessenger.show('Call end failed', _api.errorMessage(e));
      }
    } finally {
      if (!_hasEnded) {
        _hasEnded = true;
        _callSession.unregister();
        _clearSocketHandlers();
        await _cleanup();
        unawaited(_refreshWalletBalance());
        if (message != null && billing == null) {
          AppMessenger.show('Call', message);
        }
        dismissCall();
      } else {
        state = state.copyWith(isEnding: false);
      }
    }
  }

  Future<void> toggleMute() async {
    if (!state.voiceConnected) return;
    final muted = !state.isMuted;
    state = state.copyWith(isMuted: muted);
    await _zego.setMicrophoneMuted(muted);
  }

  Future<void> toggleSpeaker() async {
    if (!state.voiceConnected) return;
    final enabled = !state.isSpeakerOn;
    state = state.copyWith(isSpeakerOn: enabled);
    await _zego.setSpeakerEnabled(enabled);
  }

  Future<void> _finishCall(
    String message, {
    Map<String, dynamic>? billing,
    int? session,
    bool syncServer = false,
  }) async {
    if (_hasEnded) return;
    if (session != null && session != _session) {
      await _zego.leaveRoom();
      _zegoJoined = false;
      return;
    }

    _hasEnded = true;
    _stopBackgroundVoiceRetry();
    _callSession.unregister();
    _clearSocketHandlers();
    _timer?.cancel();

    try {
      if (syncServer && callId != null && (_callAccepted || _wasConnected)) {
        try {
          await _abortServerCall();
        } catch (_) {}
      }

      if (_zegoJoined) {
        await _zego.leaveRoom();
        await _presence.restoreAfterCall();
        _zegoJoined = false;
      } else {
        await _presence.setCallActive(false);
      }

      unawaited(_refreshWalletBalance());
      if (billing != null) {
        final deducted = JsonParse.toDouble(billing['amount_deducted']);
        AppMessenger.show(
          'Call ended',
          '$message — ₹${deducted.toStringAsFixed(2)} deducted from wallet',
          duration: const Duration(seconds: 4),
        );
      } else if (message.isNotEmpty) {
        AppMessenger.show('Call ended', message);
      }
    } finally {
      dismissCall();
    }
  }

  Future<void> _cleanup() async {
    _timer?.cancel();
    _stopBackgroundVoiceRetry();
    if (_zegoJoined) {
      await _zego.leaveRoom();
      await _presence.restoreAfterCall();
      _zegoJoined = false;
    } else {
      // Call was cancelled/rejected before Zego joined — still need to clear
      // the keepAlive flag so the boy can go offline when app backgrounds.
      await _presence.setCallActive(false);
    }
  }
}
