import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/parse_utils.dart';
import '../../data/repositories/hosts_repository_impl.dart';
import '../../domain/repositories/hosts_repository.dart';
import '../calling/calling_notifier.dart';
import '../incoming_call/incoming_call_notifier.dart';

final hostsRepositoryProvider = Provider<HostsRepository>((ref) {
  return HostsRepositoryImpl(ref.read(apiServiceProvider));
});

class HomeState {
  const HomeState({
    this.searchQuery = '',
    this.balance = 0,
    this.onlineHosts = const [],
    this.featuredHosts = const [],
    this.allHosts = const [],
    this.isLoading = false,
  });

  final String searchQuery;
  final double balance;
  final List<Map<String, dynamic>> onlineHosts;
  final List<Map<String, dynamic>> featuredHosts;
  final List<Map<String, dynamic>> allHosts;
  final bool isLoading;

  HomeState copyWith({
    String? searchQuery,
    double? balance,
    List<Map<String, dynamic>>? onlineHosts,
    List<Map<String, dynamic>>? featuredHosts,
    List<Map<String, dynamic>>? allHosts,
    bool? isLoading,
  }) {
    return HomeState(
      searchQuery: searchQuery ?? this.searchQuery,
      balance: balance ?? this.balance,
      onlineHosts: onlineHosts ?? this.onlineHosts,
      featuredHosts: featuredHosts ?? this.featuredHosts,
      allHosts: allHosts ?? this.allHosts,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Map<String, dynamic>> get filteredHosts {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return allHosts;

    return allHosts.where((host) {
      final name = host['name']?.toString().toLowerCase() ?? '';
      final languages = host['languages'] as List? ?? [];
      final langText = languages
          .map((l) => l is Map ? l['name']?.toString().toLowerCase() ?? '' : '')
          .join(' ');
      return name.contains(q) || langText.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredOnlineHosts {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return onlineHosts;

    return onlineHosts.where((host) {
      final name = host['name']?.toString().toLowerCase() ?? '';
      final languages = host['languages'] as List? ?? [];
      final langText = languages
          .map((l) => l is Map ? l['name']?.toString().toLowerCase() ?? '' : '')
          .join(' ');
      return name.contains(q) || langText.contains(q);
    }).toList();
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

class HomeNotifier extends Notifier<HomeState> {
  late final ApiService _api;
  late final SocketService _socket;
  late final PresenceService _presence;
  late final AppNavigator _navigator;
  late final HostsRepository _hostsRepo;

  @override
  HomeState build() {
    _api = ref.read(apiServiceProvider);
    _socket = ref.read(socketServiceProvider);
    _presence = ref.read(presenceServiceProvider);
    _navigator = ref.read(appNavigatorProvider);
    _hostsRepo = ref.read(hostsRepositoryProvider);

    _socket.onIncomingCall = _handleIncomingCall;
    _socket.onWalletUpdated = (_) => loadBalance();
    _socket.onHostOnline = (_) => _refreshHostLists();
    _socket.onHostOffline = (_) => _refreshHostLists();
    _socket.onHostBusy = (data) {
      final hostId = JsonParse.toInt(data['host_id']);
      if (hostId > 0) _setHostBusy(hostId, true);
    };
    _socket.onHostAvailable = (data) {
      final hostId = JsonParse.toInt(data['host_id']);
      if (hostId > 0) _setHostBusy(hostId, false);
    };
    _socket.onCallEnded = (data) {
      if (_navigator.isOnCallScreen) return;
      _refreshHostLists();
    };

    ref.onDispose(() {
      _socket.onIncomingCall = null;
      _socket.onWalletUpdated = null;
      _socket.onHostOnline = null;
      _socket.onHostOffline = null;
      _socket.onHostBusy = null;
      _socket.onHostAvailable = null;
      _socket.onCallEnded = null;
    });

    Future.microtask(() async {
      unawaited(_presence.goOnline());
      await loadAll();
    });
    return const HomeState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void _refreshHostLists() {
    loadOnlineHosts();
    loadAllHosts();
  }

  void _setHostBusy(int hostId, bool busy) {
    List<Map<String, dynamic>> patch(List<Map<String, dynamic>> list) {
      return list.map((h) {
        if (JsonParse.toInt(h['id']) == hostId) {
          return {...h, 'is_busy': busy ? 1 : 0};
        }
        return h;
      }).toList();
    }

    state = state.copyWith(
      onlineHosts: patch(state.onlineHosts),
      allHosts: patch(state.allHosts),
      featuredHosts: patch(state.featuredHosts),
    );
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    final isBusy = ref.read(callingProvider).status != CallStatus.ended ||
        ref.read(incomingCallProvider).callData.isNotEmpty;
    if (isBusy) return;
    _navigator.pushIncomingCall(data);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await loadBalance();
      await loadOnlineHosts();
      await loadFeaturedHosts();
      await loadAllHosts();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadBalance() async {
    try {
      final res = await _api.get(ApiConstants.walletBalance);
      final data = JsonParse.toMap(res['data']);
      state = state.copyWith(balance: JsonParse.toDouble(data?['balance']));
    } catch (_) {}
  }

  Future<void> loadOnlineHosts() async {
    try {
      final hosts = await _hostsRepo.getOnlineHosts();
      state = state.copyWith(
        onlineHosts: hosts.map((h) => h.toMap()).toList(),
      );
    } catch (_) {}
  }

  Future<void> loadFeaturedHosts() async {
    try {
      final hosts = await _hostsRepo.getFeaturedHosts();
      state = state.copyWith(
        featuredHosts: hosts.map((h) => h.toMap()).toList(),
      );
    } catch (_) {}
  }

  Future<void> loadAllHosts() async {
    try {
      final hosts = await _hostsRepo.getAllHosts();
      state = state.copyWith(
        allHosts: hosts.map((h) => h.toMap()).toList(),
      );
    } catch (_) {}
  }

  void openHostProfile(Map<String, dynamic> host) {
    _navigator.goHostProfile(host);
  }
}
