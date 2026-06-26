import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.maxLines = 1,
    this.fillAlpha = 1,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  const AppTextField.search({
    super.key,
    required this.onChanged,
    this.hint = 'Search by language',
    this.suffixIcon,
  })  : controller = null,
        onSubmitted = null,
        label = null,
        prefixIcon = Icons.search_rounded,
        keyboardType = null,
        textInputAction = null,
        textCapitalization = null,
        maxLines = 1,
        fillAlpha = 1,
        contentPadding = const EdgeInsets.symmetric(vertical: 14);

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final int maxLines;
  final double fillAlpha;
  final EdgeInsetsGeometry contentPadding;

  static InputDecoration decoration({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double fillAlpha = 1,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: fillAlpha),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: decoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textSecondary) : null,
        suffixIcon: suffixIcon,
        fillAlpha: fillAlpha,
        contentPadding: contentPadding,
      ),
    );
  }
}
