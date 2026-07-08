import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/call_session_service.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/services/socket_service.dart';
import '../calling/calling_notifier.dart';
import '../../core/utils/call_error_message.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';

class IncomingCallState {
  const IncomingCallState({
    this.callData = const {},
    this.isLoading = false,
  });

  final Map<String, dynamic> callData;
  final bool isLoading;

  IncomingCallState copyWith({
    Map<String, dynamic>? callData,
    bool? isLoading,
  }) {
    return IncomingCallState(
      callData: callData ?? this.callData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final incomingCallProvider =
    NotifierProvider<IncomingCallNotifier, IncomingCallState>(IncomingCallNotifier.new);

class IncomingCallNotifier extends Notifier<IncomingCallState> {
  late final ApiService _api;
  late final RingtoneService _ringtone;
  late final AppNavigator _navigator;
  late final SocketService _socket;
  late final CallSessionService _callSession;

  @override
  IncomingCallState build() {
    _api = ref.read(apiServiceProvider);
    _ringtone = ref.read(ringtoneServiceProvider);
    _navigator = ref.read(appNavigatorProvider);
    _socket = ref.read(socketServiceProvider);
    _callSession = ref.read(callSessionServiceProvider);

    ref.onDispose(() {
      _detachRemoteEndHandlers();
      _stopRingtone();
    });

    return const IncomingCallState();
  }

  void init(Map<String, dynamic>? args) {
    if (args != null) {
      state = state.copyWith(callData: Map<String, dynamic>.from(args));
    }
    final id = callId;
    if (id != null) {
      _callSession.register(id, _onRemoteCallEnded);
    }
    _attachRemoteEndHandlers();
  }

  Future<void> _onRemoteCallEnded(Map<String, dynamic> data) async {
    if (!_matchesCall(data)) return;
    await _dismissIncoming('Call ended');
  }

  void _attachRemoteEndHandlers() {
    _socket.onCallRejected = _onRemoteReject;
    _socket.onCallMissed = _onRemoteMiss;
  }

  void _detachRemoteEndHandlers() {
    if (_socket.onCallRejected == _onRemoteReject) {
      _socket.onCallRejected = null;
    }
    if (_socket.onCallMissed == _onRemoteMiss) {
      _socket.onCallMissed = null;
    }
  }

  bool _matchesCall(Map<String, dynamic> data) {
    final id = callId;
    if (id == null) return false;
    return JsonParse.toInt(data['call_id']) == id;
  }

  void _onRemoteReject(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    unawaited(_dismissIncoming('Call cancelled'));
  }

  void _onRemoteMiss(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    unawaited(_dismissIncoming('No answer'));
  }

  Future<void> _dismissIncoming(String message) async {
    await _stopRingtone();
    _detachRemoteEndHandlers();
    _callSession.unregister();
    AppMessenger.show('Call', message);
    if (_navigator.isOnCallScreen) {
      _navigator.exitCallFlow();
    }
  }

  String get callerDisplayName {
    final callData = state.callData;
    final initiatedBy = callData['initiated_by']?.toString();
    if (initiatedBy == 'female') {
      return callData['host_name']?.toString() ?? 'Host';
    }
    return callData['host_name']?.toString() ??
        callData['caller_name']?.toString() ??
        'Host';
  }

  String? get callerAvatarUrl {
    final callData = state.callData;
    final initiatedBy = callData['initiated_by']?.toString();
    if (initiatedBy == 'female') {
      return callData['host_avatar_url']?.toString();
    }
    return callData['host_avatar_url']?.toString() ??
        callData['caller_avatar_url']?.toString();
  }

  double get ratePerMinute => JsonParse.toDouble(state.callData['rate_per_minute']);

  int? get callId {
    final id = JsonParse.toInt(state.callData['call_id']);
    return id > 0 ? id : null;
  }

  Future<void> startRingtone() async {
    await _ringtone.startIncomingRingtone();
  }

  Future<void> _stopRingtone() async {
    await _ringtone.stop();
  }

  Future<void> acceptCall() async {
    final id = callId;
    if (id == null) return;

    state = state.copyWith(isLoading: true);
    await _stopRingtone();
    _detachRemoteEndHandlers();

    final mic = await requestMicrophonePermission();
    if (mic != MicPermissionOutcome.granted) {
      AppMessenger.show('Microphone required', micPermissionMessage(mic));
      if (mic == MicPermissionOutcome.permanentlyDenied) {
        await openMicrophoneSettings();
      }
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final res = await _api.post(ApiConstants.callAccept(id));
      final data = JsonParse.toMap(res['data']);
      if (data == null) {
        AppMessenger.show('Call failed', 'Invalid call response');
        return;
      }

      final token = data['zego_token']?.toString() ?? '';
      final appId = JsonParse.toInt(data['zego_app_id']);
      if (token.isEmpty || appId <= 0) {
        AppMessenger.show('Call failed', 'Voice call could not start. ZEGOCLOUD token missing.');
        return;
      }

      ref.read(callingProvider.notifier).registerOutgoingCall(id);

      _navigator.replaceCalling({
        'call_id': id,
        'host_id': state.callData['host_id'],
        'host_name': callerDisplayName,
        'host_avatar_url': callerAvatarUrl,
        'room_id': data['room_id'],
        'rate_per_minute': data['rate_per_minute'] ?? state.callData['rate_per_minute'],
        'zego_app_id': data['zego_app_id'] ?? state.callData['zego_app_id'],
        'zego_token': data['zego_token'],
        'is_outgoing': false,
        'already_connected': true,
      });
    } catch (e) {
      AppMessenger.show('Call failed', callErrorMessage(_api.errorMessage(e)));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectCall() async {
    state = state.copyWith(isLoading: true);
    await _stopRingtone();
    _detachRemoteEndHandlers();
    final id = callId;
    if (id == null) {
      _navigator.pop();
      return;
    }

    try {
      await _api.post(ApiConstants.callReject(id));
      _navigator.pop();
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
      _navigator.pop();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = const IncomingCallState();
  }
}
