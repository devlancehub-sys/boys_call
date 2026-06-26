enum ZegoJoinFailure {
  missingToken,
  invalidAppId,
  micDenied,
  micPermanentlyDenied,
  pluginMissing,
  roomError,
}

class ZegoJoinResult {
  const ZegoJoinResult._({required this.ok, this.failure, this.detail});

  const ZegoJoinResult.success() : this._(ok: true);

  const ZegoJoinResult.failure(ZegoJoinFailure failure, {String? detail})
      : this._(ok: false, failure: failure, detail: detail);

  final bool ok;
  final ZegoJoinFailure? failure;
  final String? detail;

  String get userMessage {
    if (ok) return '';
    switch (failure) {
      case ZegoJoinFailure.missingToken:
        return 'Voice token missing. Set ZEGOCLOUD on backend (Railway env) and try again.';
      case ZegoJoinFailure.invalidAppId:
        return 'ZEGOCLOUD App ID missing on server. Add ZEGOCLOUD_APP_ID on Railway.';
      case ZegoJoinFailure.micDenied:
        return 'Allow microphone access to join the voice call.';
      case ZegoJoinFailure.micPermanentlyDenied:
        return 'Microphone is blocked. Open Settings → Permissions → Microphone → Allow.';
      case ZegoJoinFailure.pluginMissing:
        return 'Zego SDK not loaded. Fully close app → install release APK (flutter build apk --release). Do not use hot reload.';
      case ZegoJoinFailure.roomError:
        final detail = this.detail ?? '';
        if (detail.contains('MissingPluginException')) {
          return 'Zego SDK not loaded. Fully close app → install release APK. Do not use hot reload.';
        }
        return detail.isNotEmpty
            ? 'Voice error: $detail'
            : 'Could not join voice room. Check ZEGOCLOUD on backend and try Retry Voice.';
      case null:
        return 'Voice call could not connect.';
    }
  }
}
