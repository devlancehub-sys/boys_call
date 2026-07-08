import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/call_error_message.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';
import '../calling/calling_notifier.dart';
import '../../data/repositories/hosts_repository_impl.dart';
import '../../domain/repositories/hosts_repository.dart';

class HostProfileState {
  const HostProfileState({
    this.host = const {},
    this.isLoading = false,
    this.isCalling = false,
  });

  final Map<String, dynamic> host;
  final bool isLoading;
  final bool isCalling;

  HostProfileState copyWith({
    Map<String, dynamic>? host,
    bool? isLoading,
    bool? isCalling,
  }) {
    return HostProfileState(
      host: host ?? this.host,
      isLoading: isLoading ?? this.isLoading,
      isCalling: isCalling ?? this.isCalling,
    );
  }
}

final hostProfileProvider =
    NotifierProvider<HostProfileNotifier, HostProfileState>(HostProfileNotifier.new);

class HostProfileNotifier extends Notifier<HostProfileState> {
  late final ApiService _api;
  late final AppNavigator _navigator;
  late final HostsRepository _hostsRepo;

  @override
  HostProfileState build() {
    _api = ref.read(apiServiceProvider);
    _navigator = ref.read(appNavigatorProvider);
    _hostsRepo = HostsRepositoryImpl(_api);
    return const HostProfileState();
  }

  void init(Map<String, dynamic>? args) {
    if (args == null) return;
    final host = Map<String, dynamic>.from(args);
    state = state.copyWith(host: host);
    final id = JsonParse.toInt(args['id']);
    if (id > 0) loadHost(id);
  }

  Future<void> loadHost(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      final entity = await _hostsRepo.getHostById(id);
      if (entity != null) {
        state = state.copyWith(host: entity.toMap());
      }
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void refreshHost() {
    final id = JsonParse.toInt(state.host['id']);
    if (id > 0) unawaited(loadHost(id));
  }

  Future<void> startCall() async {
    final host = state.host;
    final hostId = JsonParse.toInt(host['id']);
    if (hostId <= 0) return;

    state = state.copyWith(isCalling: true);
    try {
      final mic = await requestMicrophonePermission();
      if (mic != MicPermissionOutcome.granted) {
        AppMessenger.show('Microphone required', micPermissionMessage(mic));
        if (mic == MicPermissionOutcome.permanentlyDenied) {
          await openMicrophoneSettings();
        }
        return;
      }

      print('[Call Lifecycle] New call attempt: initiating call to hostId: $hostId');
      AppMessenger.show('[Call Lifecycle]', '1. Initiating new call attempt to host $hostId...');
      final res = await _api.post(ApiConstants.callsInitiate, data: {'host_id': hostId});
      print('[Call Lifecycle] Backend response received for initiate call: $res');
      final data = JsonParse.toMap(res['data']);
      if (data == null) {
        AppMessenger.show('[Call Lifecycle]', 'Error: Backend returned empty data');
        return;
      }

      AppMessenger.show('[Call Lifecycle]', '2. Call initiated! Call ID: ${data['call_id']}, Room ID: ${data['room_id']}');

      final callId = JsonParse.toInt(data['call_id']);
      final appId = JsonParse.toInt(data['zego_app_id']);
      if (appId <= 0) {
        AppMessenger.show(
          'Voice unavailable',
          'ZEGOCLOUD is not set on backend. Add ZEGOCLOUD_APP_ID and ZEGOCLOUD_SERVER_SECRET on Railway.',
        );
        return;
      }

      if (callId > 0) {
        ref.read(callingProvider.notifier).registerOutgoingCall(callId);
      }

      _navigator.pushCalling({
        'call_id': data['call_id'],
        'host_id': hostId,
        'host_name': host['name'] ?? 'Host',
        'host_avatar_url': host['avatar_url'] ?? data['host_avatar_url'],
        'room_id': data['room_id'],
        'rate_per_minute': data['rate_per_minute'],
        'zego_app_id': data['zego_app_id'],
        'zego_token': data['zego_token'],
        'is_outgoing': true,
      });
    } catch (e) {
      print('[Call Lifecycle] Call attempt failed: $e');
      AppMessenger.show('[Call Lifecycle] Call failed', callErrorMessage(_api.errorMessage(e)));
      AppMessenger.show('Call failed', callErrorMessage(_api.errorMessage(e)));
    } finally {
      state = state.copyWith(isCalling: false);
    }
  }
}
