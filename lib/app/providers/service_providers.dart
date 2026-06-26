import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/call_session_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/zego_call_service.dart';

/// Initialized in [appBootstrapProvider] — do not read before bootstrap completes.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService not initialized');
});

final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError('ApiService not initialized');
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  throw UnimplementedError('DeviceService not initialized');
});

final socketServiceProvider = Provider<SocketService>((ref) {
  throw UnimplementedError('SocketService not initialized');
});

final callSessionServiceProvider = Provider<CallSessionService>((ref) {
  throw UnimplementedError('CallSessionService not initialized');
});

final zegoCallServiceProvider = Provider<ZegoCallService>((ref) {
  throw UnimplementedError('ZegoCallService not initialized');
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  throw UnimplementedError('PresenceService not initialized');
});

final ringtoneServiceProvider = Provider<RingtoneService>((ref) {
  throw UnimplementedError('RingtoneService not initialized');
});

final appNavigatorProvider = Provider<AppNavigator>((ref) {
  throw UnimplementedError('AppNavigator not initialized');
});

/// Holds bootstrap overrides for ProviderScope.
final class AppBootstrap {
  const AppBootstrap({
    required this.overrides,
    required this.presence,
    required this.device,
    required this.socket,
    required this.zego,
  });

  final List<Override> overrides;
  final PresenceService presence;
  final DeviceService device;
  final SocketService socket;
  final ZegoCallService zego;
}
