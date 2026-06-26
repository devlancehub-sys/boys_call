import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Global snackbar helper — replaces Get.snackbar.
abstract final class AppMessenger {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
      ),
    );
  }

  static void success(String message) => show('Success', message);

  static void error(String message) => show('Error', message);

  static void info(String title, String message) => show(title, message);
}
