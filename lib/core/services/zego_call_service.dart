import '../utils/mic_permission.dart';
import '../zego/zego_voice_state_machine.dart';
import 'zego_join_result.dart';

/// ZEGOCLOUD voice via [zego_express_engine] — backend token from POST /calls/:id/join-voice.
class ZegoCallService {
  final ZegoVoiceEngine _engine = ZegoVoiceEngine();

  ZegoVoicePhase get phase => _engine.phase;

  Future<void> ensureEngine(int appId, {bool force = false}) =>
      _engine.ensureEngine(appId, force: force);

  Future<ZegoJoinResult> joinRoom({
    required String roomId,
    required String userId,
    required String userName,
    required String? token,
    required int appId,
  }) async {
    if (token == null || token.isEmpty) {
      return const ZegoJoinResult.failure(ZegoJoinFailure.missingToken);
    }
    if (appId <= 0) {
      return const ZegoJoinResult.failure(ZegoJoinFailure.invalidAppId);
    }

    final micOutcome = await requestMicrophonePermission();
    if (micOutcome == MicPermissionOutcome.denied) {
      return const ZegoJoinResult.failure(ZegoJoinFailure.micDenied);
    }
    if (micOutcome == MicPermissionOutcome.permanentlyDenied) {
      return const ZegoJoinResult.failure(ZegoJoinFailure.micPermanentlyDenied);
    }

    final result = await _engine.joinCall(
      appId: appId,
      roomId: roomId,
      userId: userId,
      userName: userName,
      token: token,
    );

    if (result.success) return const ZegoJoinResult.success();
    if (result.pluginMissing) {
      return ZegoJoinResult.failure(ZegoJoinFailure.pluginMissing, detail: result.detail);
    }
    return ZegoJoinResult.failure(ZegoJoinFailure.roomError, detail: result.detail);
  }

  Future<void> setMicrophoneMuted(bool muted) => _engine.setMicrophoneMuted(muted);

  Future<void> setSpeakerEnabled(bool enabled) => _engine.setSpeakerEnabled(enabled);

  Future<void> leaveRoom() => _engine.leaveCall();

  Future<void> destroy() => _engine.destroy();
}
