import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/service_providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/messaging/app_messenger.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/storage_service.dart';

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.termsAccepted = false,
  });

  final bool isLoading;
  final bool termsAccepted;

  LoginState copyWith({bool? isLoading, bool? termsAccepted}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);

class LoginNotifier extends Notifier<LoginState> {
  late final TextEditingController nameController;
  late final StorageService _storage;
  late final ApiService _api;
  late final DeviceService _device;
  late final PresenceService _presence;
  late final AppNavigator _navigator;

  @override
  LoginState build() {
    _storage = ref.read(storageServiceProvider);
    _api = ref.read(apiServiceProvider);
    _device = ref.read(deviceServiceProvider);
    _presence = ref.read(presenceServiceProvider);
    _navigator = ref.read(appNavigatorProvider);

    nameController = TextEditingController();
    ref.onDispose(nameController.dispose);

    final savedName = _storage.userName;
    if (savedName != null && savedName.isNotEmpty) {
      nameController.text = savedName;
      return const LoginState(termsAccepted: true);
    }
    return const LoginState();
  }

  void setTermsAccepted(bool value) {
    state = state.copyWith(termsAccepted: value);
  }

  Future<void> quickLogin() async {
    final name = nameController.text.trim();

    if (name.length < 2) {
      AppMessenger.show('Required', 'Please enter your name (at least 2 characters)');
      return;
    }

    if (!state.termsAccepted) {
      AppMessenger.show('Required', 'Please accept Terms & Conditions');
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      await _device.ensureFcmReady();
      _device.printDetails();

      final res = await _api.postAuth(ApiConstants.quickLogin, data: {
        ..._device.loginFields,
        'name': name,
      });

      final data = res['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      await _storage.saveAuth(
        accessToken: accessToken!,
        refreshToken: refreshToken!,
        userId: user['id'] as int,
        name: user['name'] as String? ?? name,
        deviceId: _device.deviceId,
      );

      await _presence.goOnline();
      await _device.syncWithServer();

      final profileRes = await _api.get(ApiConstants.profile);
      final profile = profileRes['data'] as Map<String, dynamic>?;
      final languages = profile?['languages'] as List? ?? [];

      if (languages.isEmpty) {
        _navigator.goLanguage();
      } else {
        _navigator.goHome();
      }
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
