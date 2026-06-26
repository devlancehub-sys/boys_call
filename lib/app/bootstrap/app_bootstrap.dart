import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/call_session_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/zego_call_service.dart';
import '../providers/service_providers.dart';

/// Initializes app services and Riverpod overrides.
Future<AppBootstrap> bootstrapApp() async {
  final storage = StorageService();
  await storage.init();

  final api = ApiService(storage);
  await api.init();

  final device = DeviceService(storage, api);
  final callSession = CallSessionService();
  final zego = ZegoCallService();
  final ringtone = RingtoneService(storage);

  final socket = SocketService(callSession: callSession);
  final presence = PresenceService(
    storage: storage,
    api: api,
    socket: socket,
  );
  await presence.init();

  return AppBootstrap(
    presence: presence,
    device: device,
    socket: socket,
    zego: zego,
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      apiServiceProvider.overrideWithValue(api),
      deviceServiceProvider.overrideWithValue(device),
      socketServiceProvider.overrideWithValue(socket),
      callSessionServiceProvider.overrideWithValue(callSession),
      zegoCallServiceProvider.overrideWithValue(zego),
      presenceServiceProvider.overrideWithValue(presence),
      ringtoneServiceProvider.overrideWithValue(ringtone),
    ],
  );
}

/// Call after GoRouter is created to wire navigation into socket layer.
void wireSocketNavigator(SocketService socket, AppNavigator navigator) {
  socket.navigator = navigator;
}
