import 'package:flutter/material.dart';

import 'app/bootstrap/app_bootstrap.dart';
import 'app/love_call_boys_app.dart';
import 'app/providers/service_providers.dart';
import 'app/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_navigator.dart';

export 'app/love_call_boys_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await bootstrapApp();
  await bootstrap.device.init();

  final router = createAppRouter();
  final navigator = AppNavigator(router);
  wireSocketNavigator(bootstrap.socket, navigator);

  runApp(
    LoveCallBoysApp(
      router: router,
      overrides: [
        ...bootstrap.overrides,
        appNavigatorProvider.overrideWithValue(navigator),
      ],
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await bootstrap.zego.ensureEngine(AppConfig.zegoAppId);
      debugPrint('[Main] Zego native SDK ready (post-frame)');
    } catch (e, st) {
      debugPrint('[Main] Zego post-frame init failed (will retry on call): $e\n$st');
    }
  });
}
