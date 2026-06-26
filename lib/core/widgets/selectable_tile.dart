import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.showCheck = false,
    this.centerLabel = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showCheck;
  final bool centerLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          alignment: centerLabel ? Alignment.center : null,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.glow.withValues(alpha: 0.2), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: centerLabel ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: centerLabel ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontSize: centerLabel ? 15 : 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (showCheck && selected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
