import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'animations/scale_tap.dart';
import 'app_loading_indicator.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return ScaleTap(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: width ?? double.infinity,
        height: 54,
        decoration: enabled && !outlined
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glow,
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : null,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: outlined ? Colors.transparent : AppColors.accent,
            foregroundColor: outlined ? AppColors.accent : Colors.white,
            disabledBackgroundColor: AppColors.card,
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: outlined
                  ? const BorderSide(color: AppColors.accent, width: 1.5)
                  : BorderSide.none,
            ),
          ),
          child: loading
              ? const AppLoadingIndicator.inline()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
