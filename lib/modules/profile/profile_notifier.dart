import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/parse_utils.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.callVibrateEnabled = true,
  });

  final bool isLoading;
  final bool isSaving;
  final bool callVibrateEnabled;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? callVibrateEnabled,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      callVibrateEnabled: callVibrateEnabled ?? this.callVibrateEnabled,
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileState> {
  late final TextEditingController nameController;
  late final TextEditingController aboutController;
  late final TextEditingController ageController;
  late final ApiService _api;
  late final StorageService _storage;
  late final PresenceService _presence;
  late final AppNavigator _navigator;
  bool _disposed = false;

  @override
  ProfileState build() {
    _api = ref.read(apiServiceProvider);
    _storage = ref.read(storageServiceProvider);
    _presence = ref.read(presenceServiceProvider);
    _navigator = ref.read(appNavigatorProvider);

    nameController = TextEditingController();
    aboutController = TextEditingController();
    ageController = TextEditingController();

    ref.onDispose(() {
      _disposed = true;
      nameController.dispose();
      aboutController.dispose();
      ageController.dispose();
    });

    final vibrate = _storage.callVibrateEnabled;
    Future.microtask(loadProfile);
    return ProfileState(callVibrateEnabled: vibrate);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConstants.profile);
      if (_disposed) return;

      final data = JsonParse.toMap(res['data']);
      if (data != null) {
        nameController.text = data['name']?.toString() ?? '';
        aboutController.text = data['about']?.toString() ?? '';
        final age = data['age'];
        ageController.text = age != null ? '$age' : '';
      }
    } catch (e) {
      if (!_disposed) AppMessenger.error(_api.errorMessage(e));
    } finally {
      if (!_disposed) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveProfile() async {
    state = state.copyWith(isSaving: true);
    try {
      final age = int.tryParse(ageController.text.trim());
      await _api.put(ApiConstants.profile, data: {
        'name': nameController.text.trim(),
        'about': aboutController.text.trim(),
        'age': age,
      });
      AppMessenger.success('Profile updated');
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = _storage.refreshToken;
      if (refreshToken != null) {
        await _api.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
      }
    } catch (_) {}

    await _presence.goOffline();
    await _storage.clearAuth();
    _navigator.goLogin();
  }

  Future<void> openLanguages() async {
    final updated = await _navigator.pushLanguage(fromProfile: true);
    if (updated == true && !_disposed) {
      AppMessenger.success('Languages updated');
    }
  }

  Future<void> setCallVibrateEnabled(bool value) async {
    state = state.copyWith(callVibrateEnabled: value);
    await _storage.setCallVibrateEnabled(value);
  }
}
