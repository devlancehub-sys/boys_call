import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/service_providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/messaging/app_messenger.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/parse_utils.dart';

class LanguageState {
  const LanguageState({
    this.languages = const [],
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.fromProfile = false,
  });

  final List<Map<String, dynamic>> languages;
  final Set<int> selectedIds;
  final bool isLoading;
  final bool isSaving;
  final bool fromProfile;

  LanguageState copyWith({
    List<Map<String, dynamic>>? languages,
    Set<int>? selectedIds,
    bool? isLoading,
    bool? isSaving,
    bool? fromProfile,
  }) {
    return LanguageState(
      languages: languages ?? this.languages,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      fromProfile: fromProfile ?? this.fromProfile,
    );
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, LanguageState>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<LanguageState> {
  late final ApiService _api;
  late final AppNavigator _navigator;

  @override
  LanguageState build() {
    _api = ref.read(apiServiceProvider);
    _navigator = ref.read(appNavigatorProvider);
    return const LanguageState();
  }

  void init({bool fromProfile = false}) {
    state = state.copyWith(fromProfile: fromProfile);
    loadLanguages();
  }

  Future<void> loadLanguages() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConstants.languagesList);
      final languages = JsonParse.toMapList(res['data']);
      var selectedIds = state.selectedIds;

      if (state.fromProfile) {
        final profileRes = await _api.get(ApiConstants.profile);
        final profile = JsonParse.toMap(profileRes['data']);
        final userLangs = profile?['languages'] as List? ?? [];
        selectedIds = userLangs
            .map((l) {
              if (l is Map) return JsonParse.toInt(l['id']);
              return JsonParse.toInt(l);
            })
            .where((id) => id > 0)
            .toSet();
      }

      state = state.copyWith(languages: languages, selectedIds: selectedIds);
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleLanguage(int id) {
    final selected = Set<int>.from(state.selectedIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedIds: selected);
  }

  Future<void> saveLanguages() async {
    if (state.selectedIds.isEmpty) {
      AppMessenger.error('Select at least one language');
      return;
    }

    state = state.copyWith(isSaving: true);
    try {
      await _api.put(ApiConstants.languages, data: {
        'language_ids': state.selectedIds.toList(),
      });
      if (state.fromProfile) {
        _navigator.pop(true);
      } else {
        _navigator.goHome();
      }
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
