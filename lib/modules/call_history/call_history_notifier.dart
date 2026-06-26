import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class CallHistoryState {
  const CallHistoryState({
    this.calls = const [],
    this.isLoading = false,
    this.filterTab = 0,
  });

  final List<Map<String, dynamic>> calls;
  final bool isLoading;
  final int filterTab;

  List<Map<String, dynamic>> get filteredCalls {
    switch (filterTab) {
      case 1:
        return calls.where((c) => c['initiated_by']?.toString() == 'female').toList();
      case 2:
        return calls.where((c) => c['initiated_by']?.toString() == 'male').toList();
      default:
        return calls;
    }
  }

  CallHistoryState copyWith({
    List<Map<String, dynamic>>? calls,
    bool? isLoading,
    int? filterTab,
  }) {
    return CallHistoryState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
      filterTab: filterTab ?? this.filterTab,
    );
  }
}

final callHistoryProvider =
    NotifierProvider<CallHistoryNotifier, CallHistoryState>(CallHistoryNotifier.new);

class CallHistoryNotifier extends Notifier<CallHistoryState> {
  late final ApiService _api;

  @override
  CallHistoryState build() {
    _api = ref.read(apiServiceProvider);
    Future.microtask(loadHistory);
    return const CallHistoryState();
  }

  void changeFilter(int index) {
    state = state.copyWith(filterTab: index);
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConstants.callsHistory, query: {'page': 1, 'limit': 50});
      state = state.copyWith(calls: JsonParse.toMapList(res['data']));
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
