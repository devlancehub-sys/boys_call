import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

abstract final class AppDialogs {
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel, style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: destructive ? AppColors.error : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonLabel, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  static Future<void> showLoading(BuildContext context, {String message = 'Loading...'}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
